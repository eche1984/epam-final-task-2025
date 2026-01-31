output "frontend_instance_id" {
  description = "ID of the frontend EC2 instance"
  value       = aws_instance.frontend.id
}

output "frontend_instance_private_ip" {
  description = "Private IP of the frontend EC2 instance"
  value       = aws_instance.frontend.private_ip
}

output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = aws_instance.backend.id
}

output "backend_instance_private_ip" {
  description = "Private IP of the backend EC2 instance"
  value       = aws_instance.backend.private_ip
}

output "ansible_instance_id" {
  description = "ID of the ansible EC2 instance"
  value       = aws_instance.ansible.id
}

output "ansible_instance_private_ip" {
  description = "Private IP of the ansible EC2 instance"
  value       = aws_instance.ansible.private_ip
}

output "frontend_security_group_id" {
  description = "ID of the frontend security group"
  value       = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  description = "ID of the backend security group"
  value       = aws_security_group.backend.id
}
