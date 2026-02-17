output "ansible_instance_id" {
  description = "ID of the ansible EC2 instance"
  value       = aws_instance.ansible.id
}

output "ansible_instance_private_ip" {
  description = "Private IP of the ansible EC2 instance"
  value       = aws_instance.ansible.private_ip
}

output "frontend_instance_profile" {
  description = "Name of the frontend instance profile"
  value       = aws_iam_instance_profile.frontend.name
}

output "backend_instance_profile" {
  description = "Name of the backend instance profile"
  value       = aws_iam_instance_profile.backend.name
}

output "ansible_instance_profile" {
  description = "Name of the ansible instance profile"
  value       = aws_iam_instance_profile.ansible.name
}

output "frontend_asg_name" {
  description = "Name of the Frontend ASG"
  value = aws_autoscaling_group.frontend_asg.name 
}

output "backend_asg_name" {
  description = "Name of the Backend ASG"
  value = aws_autoscaling_group.backend_asg.name
}
