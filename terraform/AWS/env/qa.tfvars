aws_region = "us-east-1"
project_name = "movie-analyst"

vpc_cidr = "192.168.16.0/20"
alb_public_subnet_cidr_1 = "192.168.16.0/25"
alb_public_subnet_cidr_2 = "192.168.16.128/25"
frontend_subnet_cidr = "192.168.17.0/25"
backend_subnet_cidr = "192.168.17.128/25"
ansible_subnet_cidr = "192.168.18.0/25"
db_subnet_group_cidr_1 = "192.168.18.128/25"
db_subnet_group_cidr_2 = "192.168.19.0/25"

ami_id = "ami-0c398cb65a93047f2"
instance_type = "t3.small"
ec2_allocated_storage = 30
ec2_storage_type = "gp3"

mysql_version = "8.0"
db_instance_class = "db.t3.micro"
rds_allocated_storage = 30
rds_storage_type = "gp3"
db_name = "movie_db"
db_username = "movie_db_user"

frontend_port = 3030
backend_port = 3000

# Monitoring Configuration
enable_monitoring = true
enable_email_notifications = false
notification_email = "ezequiel.suasnabar@gmail.com"