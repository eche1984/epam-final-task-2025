data "google_secret_manager_secret" "movie_db_user_pass" {
  secret_id = var.db_password_secret_name
  project   = "${var.project_id}"
}

data "google_secret_manager_secret_version" "password_value" {
  secret  = data.google_secret_manager_secret.movie_db_user_pass.id
  version = "latest" # Esto siempre traerá la versión más reciente
}

# Cloud SQL MySQL Instance
resource "google_sql_database_instance" "main" {
  name             = "${var.project_name}-mysql-${var.environment}"
  database_version = var.mysql_version
  region           = var.region

  settings {
    tier                        = var.db_instance_class
    deletion_protection_enabled = var.deletion_protection
    disk_type                   = var.storage_type
    disk_size                   = var.allocated_storage
    disk_autoresize             = true

    ip_configuration {      
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      enable_private_path_for_google_cloud_services = true
      allocated_ip_range                            = var.allocated_ip_range
    }

    database_flags {
      name  = "max_connections"
      value = var.max_connections
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    user_labels = {
      env     = var.environment
      name    = "${var.project_name}-mysql-${var.environment}"
    }
  }

  deletion_protection = var.deletion_protection  
}

# Database
resource "google_sql_database" "main" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
}

# Database User
resource "google_sql_user" "main" {
  name     = var.db_username
  instance = google_sql_database_instance.main.name
  password = data.google_secret_manager_secret_version.password_value.secret_data
}
