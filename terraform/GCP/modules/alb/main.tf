# Load Balancer Module for GCP (equivalent to AWS ALB)

# Health Check for Frontend Instances
resource "google_compute_health_check" "frontend" {
  name                = "${var.project_name}-frontend-hc-${var.environment}"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = var.frontend_port
  }

  log_config {
    enable = true
  }
}

# Health Check for Backend Instances (for internal LB)
resource "google_compute_health_check" "backend" {
  count               = var.create_internal_lb ? 1 : 0
  name                = "${var.project_name}-backend-hc-${var.environment}"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = var.backend_port
  }

  log_config {
    enable = true
  }
}

# Unmanaged Instance Group for Frontend (using existing instance from compute module)
resource "google_compute_instance_group" "frontend" {
  name        = "${var.project_name}-frontend-ig-${var.environment}"
  zone        = var.zone
  description = "Instance group for frontend instances"

  instances = [var.frontend_instance_id]

  named_port {
    name = "http"
    port = var.frontend_port
  }
}

# Unmanaged Instance Group for Backend (using existing instance from compute module)
resource "google_compute_instance_group" "backend" {
  count       = var.create_internal_lb ? 1 : 0
  name        = "${var.project_name}-backend-ig-${var.environment}"
  zone        = var.zone
  description = "Instance group for backend instances"

  instances = [var.backend_instance_id]

  named_port {
    name = "backend"
    port = var.backend_port
  }
}

# Load Balancer Backend Service for Frontend
resource "google_compute_backend_service" "frontend" {
  name          = "${var.project_name}-frontend-backend-${var.environment}"
  protocol      = "HTTP"
  port_name     = "http"
  health_checks = [google_compute_health_check.frontend.id]

  backend {
    group = google_compute_instance_group.frontend.id
  }

  log_config {
    enable = true
  }
}

# Backend Service for Backend (Internal Load Balancer)
resource "google_compute_backend_service" "backend" {
  count        = var.create_internal_lb ? 1 : 0
  name         = "${var.project_name}-backend-backend-${var.environment}"
  protocol     = "HTTP"
  port_name    = "backend"
  health_checks = [google_compute_health_check.backend[0].id]

  backend {
    group = google_compute_instance_group.backend[0].id
  }

  log_config {
    enable = true
  }
}

# URL Map
resource "google_compute_url_map" "frontend" {
  name            = "${var.project_name}-url-map-${var.environment}"
  default_service = google_compute_backend_service.frontend.id
}

# HTTP Target Proxy
resource "google_compute_target_http_proxy" "frontend" {
  name    = "${var.project_name}-http-proxy-${var.environment}"
  url_map = google_compute_url_map.frontend.id
}

# HTTPS Target Proxy (if SSL certificate is provided)
resource "google_compute_target_https_proxy" "frontend" {
  count          = var.ssl_certificate != "" ? 1 : 0
  name           = "${var.project_name}-https-proxy-${var.environment}"
  url_map        = google_compute_url_map.frontend.id
  ssl_certificates = [var.ssl_certificate]
}

# Forwarding Rule for HTTP
resource "google_compute_forwarding_rule" "frontend_http" {
  name       = "${var.project_name}-frontend-http-${var.environment}"
  target     = google_compute_target_http_proxy.frontend.id
  port_range = "80"
  ip_protocol = "TCP"
}

# Forwarding Rule for HTTPS (if SSL certificate is provided)
resource "google_compute_forwarding_rule" "frontend_https" {
  count       = var.ssl_certificate != "" ? 1 : 0
  name        = "${var.project_name}-frontend-https-${var.environment}"
  target      = google_compute_target_https_proxy.frontend[0].id
  port_range  = "443"
  ip_protocol = "TCP"
}

# Internal Load Balancer (for frontend to backend communication)
resource "google_compute_forwarding_rule" "backend_internal" {
  count       = var.create_internal_lb ? 1 : 0
  name        = "${var.project_name}-backend-internal-${var.environment}"
  target      = google_compute_backend_service.backend[0].id
  port_range  = "80"
  ip_protocol = "TCP"
  load_balancing_scheme = "INTERNAL"
}

# Global Static IP (optional)
resource "google_compute_global_address" "frontend" {
  count = var.create_global_ip ? 1 : 0
  name  = "${var.project_name}-frontend-ip-${var.environment}"
}

# Regional Static IP (optional)
resource "google_compute_address" "frontend" {
  count   = var.create_regional_ip ? 1 : 0
  name    = "${var.project_name}-frontend-ip-${var.environment}"
  region  = var.region
}

# Internal Static IP (optional)
resource "google_compute_address" "backend_internal" {
  count   = var.create_internal_lb ? 1 : 0
  name    = "${var.project_name}-backend-internal-ip-${var.environment}"
  region  = var.region
  address_type = "INTERNAL"
}
