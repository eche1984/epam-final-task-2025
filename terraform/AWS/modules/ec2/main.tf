# Security Groups Module
resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-sg-${var.environment}"
  description = "Security group for frontend EC2 instance"
  vpc_id      = var.vpc_id

  # Note: HTTP, HTTPS, and frontend port access will be added by ALB module
  # This ensures the frontend is only accessible through the ALB

  # Allow SSH from Ansible subnet
  ingress {
    description = "SSH from Ansible subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ansible_subnet_cidr]
  }

  # Allow SSH from internet
  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env = "${var.environment}"
  }

}

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg-${var.environment}"
  description = "Security group for backend EC2 instance"
  vpc_id      = var.vpc_id

  # Allow backend port from frontend subnet
  ingress {
    description     = "Backend API from frontend"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id,aws_security_group.ansible.id]
  }

  # Allow SSH from Ansible subnet
  ingress {
    description = "SSH from Ansible subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ansible_subnet_cidr]
  }

  # Allow SSH from internet
  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env = "${var.environment}"
  }
}

resource "aws_security_group" "ansible" {
  name        = "${var.project_name}-ansible-sg-${var.environment}"
  description = "Security group for Ansible control node"
  vpc_id      = var.vpc_id

  # Allow SSH from internet
  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env = "${var.environment}"
  }
}

locals {
  # Name of the SSM parameter (SecureString) that stores the DB password.
  # This must match the name used by the RDS module so both read the same secret.
  db_password_parameter_name = "/${var.project_name}/${var.environment}/db_password"
}

# IAM role for granting access on AWS SSM to EC2 backend instance

resource "aws_iam_role" "backend" {
  name               = "${var.project_name}-backend-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.backend_assume_role.json

  tags = {
    Env = "${var.environment}"
  }
}

# IAM policy for granting access on AWS SSM to EC2 backend instance

resource "aws_iam_role_policy" "backend_ssm" {
  name   = "${var.project_name}-backend-ssm-${var.environment}"
  role   = aws_iam_role.backend.id
  policy = data.aws_iam_policy_document.backend_ssm_policy.json
}

resource "aws_iam_instance_profile" "backend" {
  name = "${var.project_name}-backend-profile-${var.environment}"
  role = aws_iam_role.backend.name
}

# Frontend EC2 Instance
resource "aws_instance" "frontend" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.frontend_subnet_id
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  key_name                    = data.aws_key_pair.movie-analyst-frontend.key_name
  associate_public_ip_address = false

  root_block_device {
    delete_on_termination = true
    volume_size = var.allocated_storage
    volume_type = var.storage_type
    iops = 3000
    throughput = 125

    tags = {
      Name = "${var.project_name}-frontend-${var.environment}-vol-1"
      Env = "${var.environment}"
    }
  }

  user_data = <<-EOF
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

  tags = {
    Name = "${var.project_name}-frontend-${var.environment}"
    Env = "${var.environment}"
    Role = "frontend"
  }
}

# Backend EC2 Instance
resource "aws_instance" "backend" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.backend_subnet_id
  vpc_security_group_ids      = [aws_security_group.backend.id]
  key_name                    = data.aws_key_pair.movie-analyst-backend.key_name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.backend.name

  root_block_device {
    delete_on_termination = true
    volume_size = var.allocated_storage
    volume_type = var.storage_type
    iops = 3000
    throughput = 125

    tags = {
      Name = "${var.project_name}-backend-${var.environment}-vol-1"
      Env = "${var.environment}"
    }
  }
  
  user_data = <<-EOF
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

  tags = {
    Name = "${var.project_name}-backend-${var.environment}"
    Env = "${var.environment}"
    Role = "backend"
  }
}

# Ansible Control Node EC2 Instance
resource "aws_instance" "ansible" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.ansible_subnet_id
  vpc_security_group_ids      = [aws_security_group.ansible.id]
  key_name                    = data.aws_key_pair.movie-analyst-ansible.key_name
  associate_public_ip_address = false

  root_block_device {
    delete_on_termination = true
    volume_size = var.allocated_storage
    volume_type = var.storage_type
    iops = 3000
    throughput = 125

    tags = {
      Name = "${var.project_name}-ansible-${var.environment}-vol-1"
      Env = "${var.environment}"
    }
  }

  user_data = <<-EOF
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
              apt install -y python3 python3-pip awscli tree mysql-client
              apt install -y software-properties-common
              add-apt-repository --yes --update ppa:ansible/ansible
              apt install -y ansible
              pip3 install boto3 botocore
              ansible-galaxy collection install amazon.aws
              EOF

  tags = {
    Name = "${var.project_name}-ansible-${var.environment}"
    Env = "${var.environment}"
    Role = "ansible"
  }
}
