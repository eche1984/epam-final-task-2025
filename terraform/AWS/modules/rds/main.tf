# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = var.db_subnet_ids

  tags = {
    Env = "${var.environment}"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS MySQL instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-rds-sg-${var.environment}"
    Env = "${var.environment}"
  }
}

resource "aws_security_group_rule" "rds_mysql_access" {
  
  # Allow MySQL from backend and ansible subnets
  for_each = toset([var.backend_sg_id, var.ansible_sg_id])

  type                     = "ingress"
  description              = "MySQL from authorized SGs"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = each.value
}

resource "aws_security_group_rule" "rds_egress" {
  type                     = "egress"
  description              = "All outbound"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.rds.id
}

locals {
  # Resolve the SSM parameter name that contains the DB password.
  # - If the caller passes db_password_parameter_name, use that.
  # - Otherwise, fall back to the convention: /<project>/<env>/db_password
  db_password_parameter_name = coalesce(
    var.db_password_parameter_name,
    "/${var.project_name}/${var.environment}/db_password"
  )
}

# RDS MySQL Instance
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-mysql-${var.environment}"
  engine                 = "mysql"
  engine_version         = var.mysql_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  skip_final_snapshot    = true
  storage_encrypted      = true
  multi_az               = false

  db_name  = var.db_name
  username = var.db_username
  password = data.aws_ssm_parameter.db_password.value

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    Env = "${var.environment}"
  }
}
