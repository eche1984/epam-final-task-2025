data "aws_key_pair" "movie-analyst" {
  key_name = "movie-analyst-${var.environment}"
}

# Read the SSM parameter only to obtain its ARN for the IAM policy above.
# The application password will be consumed via Ansible, to not expose it
# in Terraform variables or tfvars files.
data "aws_ssm_parameter" "db_password" {
  name = var.db_password_parameter_name
}

data "aws_iam_policy_document" "ansible_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ansible_ssm_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = [
      data.aws_ssm_parameter.db_password.arn,
      var.ssm_parameter_backend_url,
      var.ssm_parameter_backend_port,
      var.ssm_parameter_frontend_url,
      var.ssm_parameter_frontend_port
    ] # In case of adding more SSM parameters, they can be referenced as arn:aws:ssm:${var.region}:${var.account_id}:parameter/${var.project_name}/${var.environment}/*
  }

  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "rds:DescribeDBInstances",
      "rds:ListTagsForResource"
    ]
    resources = ["*"]
  }
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
    actions = [
      "ec2:CreateTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "frontend_assume_role" {
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

data "aws_iam_policy_document" "frontend_ssm_policy" {
  statement {
    actions = [
      "ec2:CreateTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}
