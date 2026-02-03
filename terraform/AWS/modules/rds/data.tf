# Read DB password from SSM Parameter Store (SecureString) instead of taking it
# from tfvars. This avoids leaking the secret into Terraform configuration files.
data "aws_ssm_parameter" "db_password" {
  name            = local.db_password_parameter_name
  with_decryption = true
}
