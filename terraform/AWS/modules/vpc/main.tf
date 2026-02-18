# VPC Module for AWS

# Main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
    Env = "${var.environment}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}"
    Env = "${var.environment}"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-eip-${var.environment}"
    Env = "${var.environment}"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.alb_public[0].id

  tags = {
    Name = "${var.project_name}-nat-${var.environment}"
    Env = "${var.environment}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Subnets for ALB (required for high availability)
resource "aws_subnet" "alb_public" {
  count = 2  # Create 2 subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = count.index == 0 ? var.alb_public_subnet_cidr_1 : var.alb_public_subnet_cidr_2
  availability_zone       = count.index == 0 ? data.aws_availability_zones.available.names[0] : data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-alb-subnet-${var.environment}-${count.index + 1}"
    Type = "public"
    Env = "${var.environment}"
  }
}

# Private Subnet for Frontend
resource "aws_subnet" "frontend" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.frontend_subnet_cidr
  # The frontend subnet AZ must be one from the ALB subnets AZs to ensure app reachability
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-frontend-subnet-${var.environment}"
    Type = "private"
    Env = "${var.environment}"
  }
}

# Private Subnets for Backend and Internal ALB
resource "aws_subnet" "backend" {
  count = 2  # Create 2 subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = count.index == 0 ? var.backend_subnet_cidr_1 : var.backend_subnet_cidr_2
  availability_zone       = count.index == 0 ? data.aws_availability_zones.available.names[2] : data.aws_availability_zones.available.names[3]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-backend-subnet-${var.environment}-${count.index + 1}"
    Type = "private"
    Env = "${var.environment}"
  }  
}

# Subnet for Ansible Control Node
resource "aws_subnet" "ansible" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.ansible_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[3]
  
  tags = {
    Name = "${var.project_name}-ansible-subnet-${var.environment}"
    Type = "private"
    Env = "${var.environment}"
  }
}

# Subnets for DB Subnet Group (RDS requires at least 2 subnets in different AZs)
resource "aws_subnet" "database" {
  count = 2  # Create 2 subnets
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = count.index == 0 ? var.db_subnet_group_cidr_1 : var.db_subnet_group_cidr_2
  availability_zone       = count.index == 0 ? data.aws_availability_zones.available.names[4] : data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "${var.project_name}-db-subnet-${var.environment}-${count.index + 1}"
    Type = "private"
    Env = "${var.environment}"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
    Env = "${var.environment}"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.environment}"
    Env = "${var.environment}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "alb_public" {
  count = 2
  
  subnet_id      = aws_subnet.alb_public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "frontend" {
  subnet_id      = aws_subnet.frontend.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "backend" {
  count = 2

  subnet_id      = aws_subnet.backend[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "ansible" {
  subnet_id      = aws_subnet.ansible.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count = 2
  
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups

resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-sg-${var.environment}"
  description = "Security group for frontend EC2 instance"
  vpc_id      = aws_vpc.main.id

  tags = {
    Env = "${var.environment}"
  }
}

resource "aws_security_group_rule" "frontend_ssh" {
  # Allow SSH from Ansible subnet and EICE
  type              = "ingress"
  description       = "SSH from Ansible subnet and EICE"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ansible_subnet_cidr, "18.206.107.24/29"]
  security_group_id = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "frontend_egress" {
  # Allow all outbound traffic
  type              = "egress"
  description       = "All outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
}

resource "aws_security_group" "backend_ilb_sg" {
  name        = "${var.project_name}-backend-ilb-sg-${var.environment}"
  description = "Security group for Internal Backend ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from Frontend ASG"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-alb-sg-${var.environment}"
  }
}

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg-${var.environment}"
  description = "Security group for backend EC2 instance"
  vpc_id      = aws_vpc.main.id

  tags = {
    Env = "${var.environment}"
  }
}

resource "aws_security_group_rule" "backend_api" {
  # Allow backend port from frontend subnet
  for_each = {
    frontend     = aws_security_group.frontend.id
    backend_ilb  = aws_security_group.backend_ilb_sg.id
    ansible      = aws_security_group.ansible.id
  }

  type                     = "ingress"
  description              = "Backend API from frontend"
  from_port                = var.backend_port
  to_port                  = var.backend_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.backend.id
}

resource "aws_security_group_rule" "backend_ssh" {
  # Allow SSH from Ansible subnet and EICE
  type              = "ingress"
  description       = "SSH from Ansible subnet and EICE"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ansible_subnet_cidr, "18.206.107.24/29"]
  security_group_id = aws_security_group.backend.id
}

resource "aws_security_group_rule" "backend_egress" {
  # Allow all outbound traffic
  type              = "egress"
  description       = "All outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
}

resource "aws_security_group" "ansible" {
  name        = "${var.project_name}-ansible-sg-${var.environment}"
  description = "Security group for Ansible control node"
  vpc_id      = aws_vpc.main.id

  tags = {
    Env = "${var.environment}"
  }
}

resource "aws_security_group_rule" "ansible_ssh" {
  # Allow SSH from Backend and Frontend subnets and EICE
  type              = "ingress"
  description       = "SSH from Backend and Frontend subnets and EICE"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.frontend_subnet_cidr, var.backend_subnet_cidr_1, var.backend_subnet_cidr_2, "18.206.107.24/29"]
  security_group_id = aws_security_group.ansible.id
}

resource "aws_security_group_rule" "ansible_egress" {
  # Allow all outbound traffic
  type              = "egress"
  description       = "All outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ansible.id
}

resource "aws_security_group_rule" "allow_internal_ping" {
  for_each = {
    frontend = aws_security_group.frontend.id
    backend  = aws_security_group.backend.id
    ansible  = aws_security_group.ansible.id
  }

  type              = "ingress"
  description       = "Allow ICMP ping from VPC"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = [var.vpc_cidr] 
  security_group_id = each.value
}

resource "aws_security_group_rule" "ingress_from_eice" {
  for_each = {
    frontend = aws_security_group.frontend.id
    backend  = aws_security_group.backend.id
  }

  type                     = "ingress"
  description              = "Allow SSH from EICE SG"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eice_sg.id
  security_group_id        = each.value
}