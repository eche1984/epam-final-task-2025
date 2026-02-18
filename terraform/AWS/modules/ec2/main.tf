# EC2 Module for AWS

# IAM role for granting access to EC2 backend instance on modifying tags
resource "aws_iam_role" "backend" {
  name               = "${var.project_name}-backend-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.backend_assume_role.json

  tags = {
    Env = "${var.environment}"
  }
}

# IAM role for granting access to EC2 frontend instance on modifying tags
resource "aws_iam_role" "frontend" {
  name               = "${var.project_name}-frontend-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.frontend_assume_role.json

  tags = {
    Env = "${var.environment}"
  }
}

# IAM role for granting access on AWS SSM to EC2 ansible instance
resource "aws_iam_role" "ansible" {
  name               = "${var.project_name}-ansible-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ansible_assume_role.json

  tags = {
    Env = "${var.environment}"
  }
}

# IAM policy for granting access to EC2 backend instance on modifying tags
resource "aws_iam_role_policy" "backend_ssm" {
  name   = "${var.project_name}-backend-ssm-${var.environment}"
  role   = aws_iam_role.backend.id
  policy = data.aws_iam_policy_document.backend_ssm_policy.json
}

resource "aws_iam_instance_profile" "backend" {
  name = "${var.project_name}-backend-profile-${var.environment}"
  role = aws_iam_role.backend.name
}

# IAM policy for granting access to EC2 frontend instance on modifying tags
resource "aws_iam_role_policy" "frontend_ssm" {
  name   = "${var.project_name}-frontend-ssm-${var.environment}"
  role   = aws_iam_role.frontend.id
  policy = data.aws_iam_policy_document.frontend_ssm_policy.json
}

resource "aws_iam_instance_profile" "frontend" {
  name = "${var.project_name}-frontend-profile-${var.environment}"
  role = aws_iam_role.frontend.name
}

# IAM policy for granting access on AWS SSM to EC2 ansible instance
resource "aws_iam_role_policy" "ansible_ssm" {
  name   = "${var.project_name}-ansible-ssm-${var.environment}"
  role   = aws_iam_role.ansible.id
  policy = data.aws_iam_policy_document.ansible_ssm_policy.json
}

resource "aws_iam_instance_profile" "ansible" {
  name = "${var.project_name}-ansible-profile-${var.environment}"
  role = aws_iam_role.ansible.name
}

# Backend EC2 Launch Template
resource "aws_launch_template" "backend_lt" {
  name_prefix   = "${var.project_name}-backend-lt-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.movie-analyst.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.backend.name
  }
  
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.backend_sg_id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.allocated_storage
      volume_type           = var.storage_type
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOF
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
              apt install -y awscli tree mysql-client
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
              TAG_VALUE_SUFFIX=$(echo $INSTANCE_ID | sed 's/^i-//')
              aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value="${var.project_name}-backend-$TAG_VALUE_SUFFIX" --region ${var.region}

              VOLUME_IDS=$(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$INSTANCE_ID --region ${var.region} --query 'Volumes[*].VolumeId' --output text)
              for VOL_ID in $VOLUME_IDS; do
                aws ec2 create-tags --resources $VOL_ID --region ${var.region} --tags Key=Name,Value="${var.project_name}-backend-vol-$TAG_VALUE_SUFFIX"
              done
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Env  = "${var.environment}"
      Role = "backend"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Project = "${var.project_name}-backend-${var.environment}"
      Env     = "${var.environment}"
    }
  }
}

resource "aws_autoscaling_group" "backend_asg" {
  name                = "${var.project_name}-backend-asg-${var.environment}"
  vpc_zone_identifier = var.backend_subnet_ids
  desired_capacity    = 1
  max_size            = var.backend_max_size
  min_size            = 1
  target_group_arns   = [var.backend_tg_arn]

  health_check_type         = "EC2" # This value was changed from "ELB" to "EC2" since the ASG is too small for ELB health checks
  health_check_grace_period = 300
  
  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }
}

# Frontend EC2 Launch Template
resource "aws_launch_template" "frontend_lt" {
  name_prefix   = "${var.project_name}-frontend-lt-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.movie-analyst.key_name  

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.frontend_sg_id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.frontend.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.allocated_storage
      volume_type           = var.storage_type
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
    }
  }
  
  user_data = base64encode(<<-EOF
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
              apt install -y awscli tree mysql-client
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
              TAG_VALUE_SUFFIX=$(echo $INSTANCE_ID | sed 's/^i-//')
              aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value="${var.project_name}-frontend-$TAG_VALUE_SUFFIX" --region ${var.region}
              VOLUME_IDS=$(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$INSTANCE_ID --region ${var.region} --query 'Volumes[*].VolumeId' --output text)
              for VOL_ID in $VOLUME_IDS; do
                aws ec2 create-tags --resources $VOL_ID --region ${var.region} --tags Key=Name,Value="${var.project_name}-frontend-vol-$TAG_VALUE_SUFFIX"
              done
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Env  = "${var.environment}"
      Role = "frontend"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Project = "${var.project_name}-frontend-${var.environment}"
      Env     = "${var.environment}"
    }
  }
}

resource "aws_autoscaling_group" "frontend_asg" {
  name                = "${var.project_name}-frontend-asg-${var.environment}"
  vpc_zone_identifier = [var.frontend_subnet_id] # In the future, it can be var.frontend_subnet_ids, for HA enhancement
  desired_capacity    = 1
  max_size            = var.frontend_max_size
  min_size            = 1
  target_group_arns   = [var.frontend_tg_arn]

  health_check_type         = "EC2" # This value was changed from "ELB" to "EC2" since the ASG is too small for ELB health checks
  health_check_grace_period = 300
  
  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }
}

# Ansible Control Node EC2 Instance
resource "aws_instance" "ansible" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.ansible_subnet_id
  vpc_security_group_ids      = [var.ansible_sg_id]
  key_name                    = data.aws_key_pair.movie-analyst.key_name
  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.ansible.name

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

  user_data_base64 = base64encode(<<-EOF
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
              python3 -m pip install boto3 botocore
              ansible-galaxy collection install amazon.aws
              sudo -u ubuntu mkdir movie-analyst
              EOF
  )

  tags = {
    Name = "${var.project_name}-ansible-${var.environment}"
    Env = "${var.environment}"
    Role = "ansible"
  }
}
