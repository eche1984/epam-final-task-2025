# EICE Security Group
resource "aws_security_group" "eice_sg" {
  name        = "${var.project_name}-eice-sg-${var.environment}"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = aws_vpc.main.id

  # Allow SSH from internet
  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env = "${var.environment}"
  }
}

# EC2 Instance Connect Endpoint (EICE)
resource "aws_ec2_instance_connect_endpoint" "eice" {
  subnet_id          = aws_subnet.frontend.id
  security_group_ids = [aws_security_group.eice_sg.id]  
  
  preserve_client_ip = false

  tags = {
    Name = "${var.project_name}-eice-${var.environment}"
    Env = "${var.environment}"    
  }
}
