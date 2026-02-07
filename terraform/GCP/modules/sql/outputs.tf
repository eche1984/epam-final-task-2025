output "db_instance_id" {
  description = "ID of the database instance"
  value       = google_sql_database_instance.main.id
}

output "db_instance_name" {
  description = "Name of the database instance"
  value       = google_sql_database_instance.main.name
}

output "db_instance_connection_name" {
  description = "Connection name of the database instance"
  value       = google_sql_database_instance.main.connection_name
}

output "db_instance_ip_address" {
  description = "Private IP address of the database instance"
  value       = google_sql_database_instance.main.private_ip_address
}

output "database_name" {
  description = "Name of the database"
  value       = google_sql_database.main.name
}

output "database_user" {
  description = "Database username"
  value       = google_sql_user.main.name
}
