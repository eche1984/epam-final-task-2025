# Compute Module for GCP

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
      type  = var.disk_type
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.frontend_subnet_name
    # No public IP - will be accessed through load balancer
  }

  metadata = {
    enable-oslogin = "TRUE"
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

    apt update
    apt upgrade -y
    apt install -y tree mysql-client
  EOF

  tags = ["frontend", "allow-ssh"]

  service_account {
    email  = google_service_account.compute.email
    scopes = ["cloud-platform"]
  }

  labels = {
    env           = var.environment
    role          = "frontend"
    project       = var.project_name
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
      type  = var.disk_type
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.backend_subnet_name
    # No public IP for backend
  }

  metadata = {
    enable-oslogin = "TRUE"
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

    apt update
    apt upgrade -y
    apt install -y tree mysql-client
  EOF

  tags = ["backend", "allow-ssh"]

  service_account {
    email  = google_service_account.compute.email
    scopes = ["cloud-platform"]
  }

  labels = {
    env           = var.environment
    role          = "backend"
    project       = var.project_name
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
      type  = var.disk_type
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.ansible_subnet_name
  }

  metadata = {
    enable-oslogin = "TRUE"
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

    apt update
    apt upgrade -y
    apt install -y python3 python3-pip tree mysql-client
    apt install -y software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
    apt install -y ansible
    python3 -m pip install boto3 botocore
    ansible-galaxy collection install google.cloud
    apt install -y ca-certificates gnupg curl
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    apt install -y google-cloud-cli
    python3 -m pip install google-auth requests google-cloud-secret-manager
  EOF

  tags = ["ansible", "allow-ssh"]

  service_account {
    email  = google_service_account.compute.email
    scopes = ["cloud-platform"]
  }

  labels = {
    env           = var.environment
    role          = "ansible"
    project       = var.project_name
    instance_name = "${var.project_name}-ansible-${var.environment}"
  }
}
