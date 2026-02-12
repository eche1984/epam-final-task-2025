# Compute Module for GCP

# Frontend Instance Template
resource "google_compute_instance_template" "frontend" {
  name         = "${var.project_name}-frontend-template-${var.environment}"
  machine_type = var.machine_type
  
  disk {   
    source_image  = var.image
    disk_size_gb  = var.allocated_storage
    disk_type     = var.disk_type
    auto_delete   = true
    boot          = true
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.frontend_subnet_name
    # No public IP - will be accessed through load balancer
  }

  lifecycle {
    # Prevent the lack of templates for the MIG to cause downtime
    create_before_destroy = true
  }

  metadata = {
    backend_ip   = "${var.backend_ilb_ip}"
    backend_port = "${var.backend_port}"
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

    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh && sudo bash add-google-cloud-ops-agent-repo.sh --install
  EOF

  tags = ["frontend", "allow-ssh"]

  service_account {
    email  = var.compute_sa_email
    scopes = ["cloud-platform"]
  }

  labels = {
    env           = var.environment
    role          = "frontend"
    project       = var.project_name
  }
}

# Backend VM Instance
resource "google_compute_instance_template" "backend" {
  name         = "${var.project_name}-backend-template-${var.environment}"
  machine_type = var.machine_type
  
  disk {   
    source_image  = var.image
    disk_size_gb  = var.allocated_storage
    disk_type     = var.disk_type
    auto_delete   = true
    boot          = true
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.backend_subnet_name
    # No public IP for backend
  }

  lifecycle {
    # Prevent the lack of templates for the MIG to cause downtime
    create_before_destroy = true
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
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh && sudo bash add-google-cloud-ops-agent-repo.sh --install
  EOF

  tags = ["backend", "allow-ssh"]

  service_account {
    email  = var.compute_sa_email
    scopes = ["cloud-platform"]
  }

  labels = {
    env           = var.environment
    role          = "backend"
    project       = var.project_name
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
    sudo -u ubuntu ssh-keygen -t rsa -b 4096 -f /home/ubuntu/.ssh/id_rsa -N "" -q
    sudo -u ubuntu gcloud compute os-login ssh-keys add --key-file=/home/ubuntu/.ssh/id_rsa.pub

    sudo -u ubuntu cat << EOC > /home/ubuntu/.ssh/config
    Host backend-* frontend-* movie-analyst-*
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
        ProxyCommand bash -c 'ZONE=\$(gcloud compute instances list --filter="name=(%h)" --format="value(zone)") && gcloud compute start-iap-tunnel %h %p --listen-on-stdin --project=courseproject-20201117 --zone=\$ZONE'
    Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_rsa
    EOC
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh && sudo bash add-google-cloud-ops-agent-repo.sh --install
  EOF

  tags = ["ansible", "allow-ssh"]

  service_account {
    email  = var.ansible_sa_email
    scopes = ["cloud-platform"]
  }

  labels = {
    env           = var.environment
    role          = "ansible"
    project       = var.project_name
  }
}

resource "google_compute_region_instance_group_manager" "frontend" {
  name               = "${var.project_name}-frontend-mig-${var.environment}"
  region             = var.region
  base_instance_name = "frontend"
  
  version {
    instance_template = google_compute_instance_template.frontend.id
  }
  
  named_port {
    name = "http"
    port = var.frontend_port
  }
}

resource "google_compute_region_instance_group_manager" "backend" {
  name               = "${var.project_name}-backend-mig-${var.environment}"
  region             = var.region
  base_instance_name = "backend"

  version {
    instance_template = google_compute_instance_template.backend.id
  }

  named_port {
    name = "backend"
    port = var.backend_port
  }
}

resource "google_compute_region_autoscaler" "frontend" {
  name   = "${var.project_name}-frontend-as-${var.environment}"
  region = var.region
  target = google_compute_region_instance_group_manager.frontend.id

  autoscaling_policy {
    max_replicas    = var.frontend_max_replicas
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.9
    }
  }
}

resource "google_compute_region_autoscaler" "backend" {
  name   = "${var.project_name}-backend-as-${var.environment}"
  region = var.region
  target = google_compute_region_instance_group_manager.backend.id

  autoscaling_policy {
    max_replicas    = var.backend_max_replicas
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.9
    }
  }
}