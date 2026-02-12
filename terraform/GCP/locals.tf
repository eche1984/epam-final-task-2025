locals {
  env_name = terraform.workspace

  # Name of the Secret Manager secret that stores the DB password.
  # NOTE: The value of this secret is created/managed by Terraform,
  # but in production you might want to manage it externally.
  db_password_secret_name = "${var.project_name}-${local.env_name}-db-password"
}

