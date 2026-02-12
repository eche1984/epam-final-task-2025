# VPC Network Module for GCP

locals {
  internal_subnets = [
    var.frontend_subnet_cidr,
    var.backend_subnet_cidr,
    var.ansible_subnet_cidr
  ]

  # Official Google's CIDR blocks for Health Checks and Load Balancers
  google_health_check_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22","209.85.204.0/22"]
}

resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc-${var.environment}"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"

  /* tags = {
    Environment = var.environment
    Project     = var.project_name
  }
  */
}

resource "google_compute_project_metadata_item" "enable_oslogin" {
  key   = "enable-oslogin"
  value = "TRUE"
}

# Private Subnet for Frontend
resource "google_compute_subnetwork" "frontend" {
  name          = "${var.project_name}-frontend-subnet-${var.environment}"
  ip_cidr_range = var.frontend_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
  }
}

# Private Subnet for Backend
resource "google_compute_subnetwork" "backend" {
  name          = "${var.project_name}-backend-subnet-${var.environment}"
  ip_cidr_range = var.backend_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
  }
}

# Subnet for Ansible Control Node
resource "google_compute_subnetwork" "ansible" {
  name          = "${var.project_name}-ansible-subnet-${var.environment}"
  ip_cidr_range = var.ansible_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
  }
}

# Subred especial para el Internal Load Balancer (Proxy-only)
resource "google_compute_subnetwork" "proxy_only" {
  name          = "${var.project_name}-ilb-proxy-subnet-${var.environment}"
  ip_cidr_range = var.ilb_private_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
  
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# CIDR block reserved for PSA
# If necessary, it's possible to create another compute_global_address with another CIDR block
resource "google_compute_global_address" "psa_range" {
  name          = "${var.project_name}-psa-range-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  address       = var.db_subnet_cidr
  network       = google_compute_network.main.id
}

# Peering with Google Services (PSA)
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"

  # Now we have one CIDR block. If necessary, it's possible to add another range for PSA
  reserved_peering_ranges = [google_compute_global_address.psa_range.name]
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "main" {
  name    = "${var.project_name}-router-${var.environment}"
  region  = var.region
  network = google_compute_network.main.id

  # Uncomment if necessary to connect to a VPN
  # bgp {
  #   asn = 64514
  # }
}

# NAT Gateway for Private Subnets
resource "google_compute_router_nat" "main" {
  name                               = "${var.project_name}-nat-${var.environment}"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rules

# Allow internal communication between GCE subnets
resource "google_compute_firewall" "allow_internal_comm" {
  name    = "${var.project_name}-allow-internal-comm-${var.environment}"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  allow { protocol = "icmp" }
  
  source_ranges = local.internal_subnets
  target_tags   = ["frontend", "backend", "ansible"]
}

# Allow backend port from GCE privates subnets, ILB and health checks
resource "google_compute_firewall" "allow_backend_app_traffic" {
  name    = "${var.project_name}-allow-backend-app-${var.environment}"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = [var.backend_port]
  }

  source_ranges = concat(
    local.internal_subnets,
    [var.ilb_private_subnet_cidr],
    local.google_health_check_ranges
  )

  target_tags = ["backend"]
}

# Allow frontend port from GCE private subnets, ALB and health checks
resource "google_compute_firewall" "allow_frontend_app_traffic" {
  name    = "${var.project_name}-allow-frontend-app-${var.environment}"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = [var.frontend_port]
  }

  source_ranges = concat(
    local.internal_subnets,
    local.google_health_check_ranges
  )

  target_tags = ["frontend"]
}

# Allow MySQL from private subnets
resource "google_compute_firewall" "allow_db_traffic" {
  name    = "${var.project_name}-allow-db-mysql-${var.environment}"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = local.internal_subnets
  target_tags   = ["mysql"]
}

# Google's Identity-Aware Proxy tunnel
resource "google_compute_firewall" "allow_ssh_from_iap" {
  name    = "${var.project_name}-allow-ssh-from-iap-${var.environment}"
  network = google_compute_network.main.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["ansible", "frontend", "backend"]
}

# Global static public IP for the ALB
resource "google_compute_global_address" "frontend" {
  name = "${var.project_name}-frontend-ip-${var.environment}"
}

# Private IP for internal communication Frontend -> Backend
resource "google_compute_address" "backend_internal" {
  name         = "${var.project_name}-backend-internal-ip-${var.environment}"
  region       = var.region
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT" # For ILB usage
  subnetwork   = google_compute_subnetwork.backend.self_link
}
