# --- Service Accounts ---

resource "google_service_account" "ansible_sa" {
  account_id   = "${var.project_name}-ansible-sa-${local.env_name}"
  display_name = "Ansible instance SA"
}

resource "google_service_account" "compute_sa" {
  account_id   = "${var.project_name}-compute-sa-${local.env_name}"
  display_name = "Compute instance (backend and frontend) SA"
}

# --- IAM Permissions ---

resource "google_project_iam_custom_role" "ansible_executor" {
  role_id     = "ansibleExecutor"
  title       = "Ansible Executor Role"
  description = "The least permissions for the Ansible SA to manage VMs and read SQL/Secrets"
  permissions = [
    # --- OS LOGIN & SSH ---
    "compute.instances.osAdminLogin",
    "compute.projects.get",
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.get",
    "resourcemanager.projects.get",

    # --- INFRASTRUCTURE DISCOVERY (Inventory & Tunnel) ---
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.setMetadata",
    "compute.zones.list",
    "compute.networks.list",

    # --- CLOUD SQL ---
    "cloudsql.instances.get",
    "cloudsql.instances.list",
    "cloudsql.databases.list",

    # --- SECRET MANAGER ---
    "secretmanager.secrets.get",
    "secretmanager.secrets.list",
    "secretmanager.versions.get",
    "secretmanager.versions.list",
    "secretmanager.versions.access",

    # --- SYSTEM / API USAGE ---
    "serviceusage.services.get",
    "serviceusage.services.list",
    "serviceusage.services.use"
  ]
}

resource "google_project_iam_member" "bind_custom_role" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.ansible_executor.id
  member  = "serviceAccount:${google_service_account.ansible_sa.email}"
}

# Ansible SA needs to be the "ADMIN" of OS Login to enter other VMs
resource "google_project_iam_member" "ansible_sa_os_admin" {
  project = var.gcp_project_id
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${google_service_account.ansible_sa.email}"
}

resource "google_project_iam_member" "ansible_sa_iap_tunnel" {
  project = var.gcp_project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${google_service_account.ansible_sa.email}"
}

resource "google_project_iam_member" "ansible_sa_user" {
  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.ansible_sa.email}"
}