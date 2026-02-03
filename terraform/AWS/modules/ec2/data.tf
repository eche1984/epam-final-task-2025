data "aws_key_pair" "movie-analyst-ansible" {
  key_name = "movie-analyst-ansible_dev"
}

data "aws_key_pair" "movie-analyst-frontend" {
  key_name = "movie-analyst-frontend_dev"
}

data "aws_key_pair" "movie-analyst-backend" {
  key_name = "movie-analyst-backend_dev"
}

data "aws_iam_policy_document" "backend_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "backend_ssm_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [data.aws_ssm_parameter.db_password.arn]
  }
}

# Read the SSM parameter only to obtain its ARN for the IAM policy above.
# The application password will be consumed via Ansible, to not expose it
# in Terraform variables or tfvars files.
data "aws_ssm_parameter" "db_password" {
  name = local.db_password_parameter_name
}
