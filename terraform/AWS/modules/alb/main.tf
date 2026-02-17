# Load Balancer Module for AWS

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # Allow HTTP from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
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
    Name = "${var.project_name}-alb-sg-${var.environment}"
    Env = "${var.environment}"
  }
}

# Internal Application Load Balancer
resource "aws_lb" "backend_ilb" {
  name               = "${var.project_name}-backend-ilb-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.backend_ilb_sg_id]
  subnets            = var.backend_subnet_ids

  tags = {
    Name = "${var.project_name}-ilb-${var.environment}"
    Env = "${var.environment}"
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.project_name}-backend-tg-${var.environment}"
  port     = var.backend_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-backend-tg-${var.environment}"
    Env = "${var.environment}"
  }
}

# External Application Load Balancer
resource "aws_lb" "frontend_alb" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb-${var.environment}"
    Env = "${var.environment}"
  }
}

# Security Group Rules: Allow ALB to communicate with Frontend
resource "aws_security_group_rule" "alb_to_frontend_app" {
  type                     = "ingress"
  from_port                = var.frontend_port
  to_port                  = var.frontend_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = var.frontend_sg_id
  description              = "Frontend app port from ALB"
}

# Target Group for Frontend
resource "aws_lb_target_group" "frontend_tg" {
  name     = "${var.project_name}-frontend-tg-${var.environment}"
  port     = var.frontend_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-frontend-tg-${var.environment}"
    Env = "${var.environment}"
  }
}

# HTTP Listener
resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  tags = {
    Name = "${var.project_name}-frontend-alb-listener-${var.environment}"
    Env = "${var.environment}"
  }
}

# Backend HTTP Listener
resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.backend_ilb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  tags = {
    Name = "${var.project_name}-backend-ilb-listener-${var.environment}"
    Env = "${var.environment}"
  }
}

# Frontend DNS for External ALB SSM Parameter
resource "aws_ssm_parameter" "frontend_url" {
  name  = "/${var.project_name}/${var.environment}/frontend/frontend_url"
  type  = "String"
  value = aws_lb.frontend_alb.dns_name
}

# Backend DNS for Internal ALB SSM Parameter
resource "aws_ssm_parameter" "backend_url" {
  name  = "/${var.project_name}/${var.environment}/backend/backend_url"
  type  = "String"
  value = aws_lb.backend_ilb.dns_name
}

# Frontend Port SSM Parameter
resource "aws_ssm_parameter" "frontend_port" {
  name  = "/${var.project_name}/${var.environment}/frontend/frontend_port"
  type  = "String"
  value = var.frontend_port
}

# Backend Port SSM Parameter
resource "aws_ssm_parameter" "backend_port" {
  name  = "/${var.project_name}/${var.environment}/backend/backend_port"
  type  = "String"
  value = var.backend_port
}
