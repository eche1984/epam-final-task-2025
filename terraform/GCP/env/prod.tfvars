gcp_project_id = "courseproject-20201117"
region = "us-east1"
zone = "us-east1-a"
project_name = "movie-analyst"
service_account_email = "terraform-sa@courseproject-20201117.iam.gserviceaccount.com"

vpc_cidr = "192.168.0.0/20"
frontend_subnet_cidr = "192.168.0.0/24"
backend_subnet_cidr = "192.168.1.0/24"
ilb_private_subnet_cidr = "192.168.2.0/24"
ansible_subnet_cidr = "192.168.3.0/24"
db_subnet_cidr = "192.168.4.0" # No need to specify the range since this block it's for PSA

frontend_port = 3030
backend_port = 3000

image = "ubuntu-os-cloud/ubuntu-2204-lts"
machine_type = "e2-micro"
allocated_storage = 30
disk_type = "PD_SSD"

mysql_version = "MYSQL_8_0"
db_tier = "db-f1-micro"
db_allocated_storage = 30
db_disk_type = "PD_SSD"
db_name = "movie_db"
db_username = "movie_db_user"

# Monitoring Configuration
enable_monitoring = true
enable_email_notifications = false
notification_email = "ezequiel.suasnabar@gmail.com"