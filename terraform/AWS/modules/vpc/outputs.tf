output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "alb_public_subnets_ids" {
  description = "List of public subnet IDs (for ALB)"
  value       = aws_subnet.alb_public[*].id
}

output "alb_public_subnets_cidr_blocks" {
  description = "List of public subnet CIDR blocks (for ALB)"
  value       = aws_subnet.alb_public[*].cidr_block
}

output "frontend_subnet_id" {
  description = "ID of the frontend subnet"
  value       = aws_subnet.frontend.id
}

output "frontend_subnet_cidr_block" {
  description = "The CIDR block of the frontend subnet"
  value       = aws_subnet.frontend.cidr_block
}

output "internal_alb_subnets_ids" {
  description = "IDs of the internal ALB subnets"
  value       = aws_subnet.backend[*].id
}

output "internal_alb_subnets_cidr_blocks" {
  description = "The CIDR blocks of the internal ALB subnets"
  value       = aws_subnet.backend[*].cidr_block
}

output "backend_subnet_id" {
  description = "ID of the backend subnet"
  value       = aws_subnet.backend[0].id
}

output "backend_subnet_cidr_block" {
  description = "The CIDR block of the backend subnet"
  value       = aws_subnet.backend[0].cidr_block
}

output "ansible_subnet_id" {
  description = "ID of the ansible subnet"
  value       = aws_subnet.ansible.id
}

output "ansible_subnet_cidr_block" {
  description = "The CIDR block of the ansible subnet"
  value       = aws_subnet.ansible.cidr_block
}

output "db_subnets_ids" {
  description = "List of database subnet IDs (for RDS subnet group)"
  value       = aws_subnet.database[*].id
}

output "db_subnets_cidr_blocks" {
  description = "The CIDR blocks of the DB subnets (for RDS subnet group)"
  value       = aws_subnet.database[*].cidr_block
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "ansible_sg_id" {
  description = "ID of the ansible security group"
  value       = aws_security_group.ansible.id
}

output "frontend_sg_id" {
  description = "ID of the frontend security group"
  value       = aws_security_group.frontend.id
}

output "backend_sg_id" {
  description = "ID of the backend security group"
  value       = aws_security_group.backend.id
}

output "backend_ilb_sg_id" {
  description = "ID of the backend ALB security group"
  value       = aws_security_group.backend_ilb_sg.id
}