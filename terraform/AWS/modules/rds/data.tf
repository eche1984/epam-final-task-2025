locals {
  # Resolve the SSM parameter name that contains the DB password.
  # - If the caller passes db_password_parameter_name, use that.
  # - Otherwise, fall back to the convention: /<project>/<env>/db_password
  db_password_parameter_name = coalesce(
    var.db_password_parameter_name,
    "/${var.project_name}/${var.environment}/db_password"
  )
}

# Read DB password from SSM Parameter Store (SecureString) instead of taking it
# from tfvars. This avoids leaking the secret into Terraform configuration files.
data "aws_ssm_parameter" "db_password" {
  name            = local.db_password_parameter_name
  with_decryption = true
}
