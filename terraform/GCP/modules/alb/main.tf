# Load Balancer Module for GCP

# Health Check for Frontend Instances
resource "google_compute_health_check" "frontend" {
  name                = "${var.project_name}-frontend-hc-${var.environment}"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port = var.frontend_port
  }

  log_config {
    enable = true
  }
}

resource "google_compute_health_check" "backend_native" {
  name               = "${var.project_name}-backend-hc-${var.environment}"
  check_interval_sec = 5
  timeout_sec        = 5

  http_health_check {
    port         = var.backend_port
    request_path = "/"
  }
}

# Health Check for Backend Instances (for internal LB)
resource "google_compute_region_health_check" "backend" {
  name                = "${var.project_name}-backend-hc-${var.environment}"
  region              = var.region
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.backend_port
    request_path = "/"
  }

  log_config {
    enable = true
  }
}

# Backend Service Global so ALB Externo can reach Backend VMs
resource "google_compute_backend_service" "backend_external_bridge" {
  name                  = "${var.project_name}-backend-ext-bridge-${var.environment}"
  protocol              = "HTTP"
  port_name             = "backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  
  # Using the global Health Check for the Backend Native Service
  health_checks         = [google_compute_health_check.backend_native.id]

  backend {
    group           = var.backend_mig_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# Load Balancer Backend Service for Frontend
resource "google_compute_backend_service" "frontend" {
  name                  = "${var.project_name}-frontend-backend-${var.environment}"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"  
  health_checks         = [google_compute_health_check.frontend.id]

  backend {
    group = var.frontend_mig_link
  }

  log_config {
    enable = true
  }
}

resource "google_compute_url_map" "frontend" {
  name            = "${var.project_name}-url-map-${var.environment}"
  default_service = google_compute_backend_service.frontend.id
  /*
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.frontend.id
    
    path_rule {
      paths   = ["/movies", "/movies/*", "/authors", "/authors/*", "/publications", "/publications/*"]
      service = google_compute_backend_service.backend_external_bridge.id
    }
  }*/
}

resource "google_compute_target_http_proxy" "frontend" {
  name    = "${var.project_name}-http-proxy-${var.environment}"
  url_map = google_compute_url_map.frontend.id
}

# HTTPS Target Proxy (if SSL certificate is provided)
/*resource "google_compute_target_https_proxy" "frontend" {
  name           = "${var.project_name}-https-proxy-${var.environment}"
  url_map        = google_compute_url_map.frontend.id
  ssl_certificates = [var.ssl_certificate]
}*/

# Forwarding Rule for HTTP
resource "google_compute_global_forwarding_rule" "frontend_http" {
  name                  = "${var.project_name}-frontend-http-${var.environment}"
  ip_address            = var.static_ip_address
  target                = google_compute_target_http_proxy.frontend.id
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# Forwarding Rule for HTTPS (if SSL certificate is provided)
/*resource "google_compute_forwarding_rule" "frontend_https" {
  name        = "${var.project_name}-frontend-https-${var.environment}"
  target      = google_compute_target_https_proxy.frontend[0].id
  port_range  = "443"
  ip_protocol = "TCP"
}*/

# Backend Service for Backend (Internal Load Balancer)
resource "google_compute_region_backend_service" "backend" {
  name                  = "${var.project_name}-backend-internal-${var.environment}"
  region                = var.region  
  protocol              = "HTTP"
  port_name             = "backend"
  load_balancing_scheme = "INTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.backend.id]

  backend {
    group           = var.backend_mig_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable = true
  }
}

resource "google_compute_region_url_map" "backend" {
  name            = "${var.project_name}-backend-map-${var.environment}"
  region          = var.region
  default_service = google_compute_region_backend_service.backend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_region_backend_service.backend.id
    
    path_rule {
      paths   = ["/api/*"]
      service = google_compute_region_backend_service.backend.id
      route_action {
        url_rewrite {
          path_prefix_rewrite = "/"
        }
      }
    }
  }
}

resource "google_compute_region_target_http_proxy" "backend" {
  name    = "${var.project_name}-backend-proxy-${var.environment}"
  region  = var.region
  url_map = google_compute_region_url_map.backend.id
}

# Internal Load Balancer (for frontend to backend communication)
resource "google_compute_forwarding_rule" "backend_internal" {
  name                  = "${var.project_name}-backend-internal-rule-${var.environment}"
  region                = var.region
  network               = var.network_id
  subnetwork            = var.backend_subnet_id
  ip_address            = var.internal_ip_address
  target                = google_compute_region_target_http_proxy.backend.id
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
}
