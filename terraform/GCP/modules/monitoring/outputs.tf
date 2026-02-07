output "frontend_log_sink" {
  description = "Frontend log sink name"
  value       = google_logging_project_sink.frontend_logs.name
}

output "backend_log_sink" {
  description = "Backend log sink name"
  value       = google_logging_project_sink.backend_logs.name
}

output "ansible_log_sink" {
  description = "Ansible log sink name"
  value       = google_logging_project_sink.ansible_logs.name
}

output "notification_channel" {
  description = "Email notification channel"
  value       = var.enable_email_notifications ? google_monitoring_notification_channel.email[0].name : null
}

output "dashboard" {
  description = "Monitoring dashboard"
  value       = google_monitoring_dashboard.main.dashboard_json
}

output "alert_policies" {
  description = "List of alert policy names"
  value = [
    google_monitoring_alert_policy.frontend_cpu_high.display_name,
    google_monitoring_alert_policy.backend_cpu_high.display_name,
    google_monitoring_alert_policy.sql_cpu_high.display_name,
    google_monitoring_alert_policy.sql_storage_low.display_name,
    google_monitoring_alert_policy.sql_connections_high.display_name
  ]
}
