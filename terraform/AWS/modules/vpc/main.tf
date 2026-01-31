# VPC Module for AWS
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
  availability_zone       = data.aws_availability_zones.available.names[2]

  tags = {
    Name = "${var.project_name}-frontend-subnet-${var.environment}"
    Type = "private"
    Env = "${var.environment}"
  }
}

# Private Subnet for Backend
resource "aws_subnet" "backend" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.backend_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[3]

  tags = {
    Name = "${var.project_name}-backend-subnet-${var.environment}"
    Type = "private"
    Env = "${var.environment}"
  }
}

# Subnet for Ansible Control Node
resource "aws_subnet" "ansible" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.ansible_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[4]
  
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
  availability_zone       = count.index == 0 ? data.aws_availability_zones.available.names[0] : data.aws_availability_zones.available.names[4]
  
  tags = {
    Name = "${var.project_name}-db-subnet-${var.environment}-${count.index + 1}"
    Type = "private"
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
  subnet_id      = aws_subnet.backend.id
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
