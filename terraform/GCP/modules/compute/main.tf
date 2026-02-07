# Compute Module for GCP (equivalent to AWS EC2)

# Service Account for Compute Instances
resource "google_service_account" "compute" {
  account_id   = "${var.project_name}-compute-sa-${var.environment}"
  display_name = "Compute Service Account"
}

# IAM Role for Backend Instance (equivalent to AWS SSM access)
resource "google_project_iam_member" "backend_secret_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.compute.email}"
}

# Frontend VM Instance
resource "google_compute_instance" "frontend" {
  name         = "${var.project_name}-frontend-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.allocated_storage
      type  = var.storage_type
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.frontend_subnet_name
    # No public IP - will be accessed through load balancer
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sleep 30

    # Wait for network to be fully ready
    echo "Waiting for network to be ready..."
    for i in {1..30}; do
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            echo "Network is ready after $((i*5)) seconds"
            break
        fi
        sleep 5
    done

    apt-get update
    apt-get upgrade -y
  EOF

  tags = ["frontend", "allow-ssh"]

  service_account {
    email  = google_service_account.compute.email
    scopes = ["cloud-platform"]
  }

  labels = {
    environment = var.environment
    type        = "frontend"
    project     = var.project_name
    instance_name = "${var.project_name}-frontend-${var.environment}"
  }
}

# Backend VM Instance
resource "google_compute_instance" "backend" {
  name         = "${var.project_name}-backend-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.allocated_storage
      type  = var.storage_type
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.backend_subnet_name
    # No public IP for backend
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sleep 30

    # Wait for network to be fully ready
    echo "Waiting for network to be ready..."
    for i in {1..30}; do
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            echo "Network is ready after $((i*5)) seconds"
            break
        fi
        sleep 5
    done

    apt-get update
    apt-get upgrade -y
    apt-get install -y mysql-client
  EOF

  tags = ["backend", "allow-ssh"]

  service_account {
    email  = google_service_account.compute.email
    scopes = ["cloud-platform"]
  }

  labels = {
    environment = var.environment
    type        = "backend"
    project     = var.project_name
    instance_name = "${var.project_name}-backend-${var.environment}"
  }
}

# Ansible Control Node VM Instance
resource "google_compute_instance" "ansible" {
  name         = "${var.project_name}-ansible-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.allocated_storage
      type  = var.storage_type
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.ansible_subnet_name
    access_config {
      # Ephemeral public IP for Ansible control node
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sleep 30

    # Wait for network to be fully ready
    echo "Waiting for network to be ready..."
    for i in {1..30}; do
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            echo "Network is ready after $((i*5)) seconds"
            break
        fi
        sleep 5
    done

    apt-get update
    apt-get upgrade -y
    apt-get install -y python3 python3-pip ansible
    pip3 install google-auth google-cloud-compute
  EOF

  tags = ["ansible", "allow-ssh"]

  service_account {
    email  = google_service_account.compute.email
    scopes = ["cloud-platform"]
  }

  labels = {
    environment = var.environment
    type        = "ansible"
    project     = var.project_name
    instance_name = "${var.project_name}-ansible-${var.environment}"
  }
}
