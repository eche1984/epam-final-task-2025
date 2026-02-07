# Monitoring Module for GCP (equivalent to AWS CloudWatch)

# Log Sinks for Compute Instances
resource "google_logging_project_sink" "frontend_logs" {
  name        = "${var.project_name}-frontend-logs-sink-${var.environment}"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.project_name}_frontend_logs_${var.environment}"
  
  filter = "resource.type=\"gce_instance\" AND labels.instance_name=\"${var.frontend_instance_name}\""
  
  unique_writer_identity = true
}

resource "google_logging_project_sink" "backend_logs" {
  name        = "${var.project_name}-backend-logs-sink-${var.environment}"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.project_name}_backend_logs_${var.environment}"
  
  filter = "resource.type=\"gce_instance\" AND labels.instance_name=\"${var.backend_instance_name}\""
  
  unique_writer_identity = true
}

resource "google_logging_project_sink" "ansible_logs" {
  name        = "${var.project_name}-ansible-logs-sink-${var.environment}"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.project_name}_ansible_logs_${var.environment}"
  
  filter = "resource.type=\"gce_instance\" AND labels.instance_name=\"${var.ansible_instance_name}\""
  
  unique_writer_identity = true
}

# Notification Channels (conditionally created)
resource "google_monitoring_notification_channel" "email" {
  count        = var.enable_email_notifications && var.notification_email != "" ? 1 : 0
  display_name = "${var.project_name}-email-notification-${var.environment}"
  type         = "email"
  
  labels = {
    email_address = var.notification_email
  }
}

# Alert Policies for Compute Instances
resource "google_monitoring_alert_policy" "frontend_cpu_high" {
  display_name = "${var.project_name}-frontend-cpu-high-${var.environment}"
  combiner     = "OR"
  enabled      = "true"

  conditions {
    display_name = "Frontend CPU High"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\" AND metadata.user_labels.instance_name=\"${var.frontend_instance_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.enable_email_notifications ? [google_monitoring_notification_channel.email[0].name] : []

  documentation {
    content = "Frontend instance CPU utilization is above 80%"
  }
}

resource "google_monitoring_alert_policy" "backend_cpu_high" {
  display_name = "${var.project_name}-backend-cpu-high-${var.environment}"
  combiner     = "OR"
  enabled      = "true"

  conditions {
    display_name = "Backend CPU High"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\" AND metadata.user_labels.instance_name=\"${var.backend_instance_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.enable_email_notifications ? [google_monitoring_notification_channel.email[0].name] : []

  documentation {
    content = "Backend instance CPU utilization is above 80%"
  }
}

# Alert Policies for Cloud SQL
resource "google_monitoring_alert_policy" "sql_cpu_high" {
  display_name = "${var.project_name}-sql-cpu-high-${var.environment}"
  combiner     = "OR"
  enabled      = "true"

  conditions {
    display_name = "SQL CPU High"
    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\" AND resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.sql_instance_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.enable_email_notifications ? [google_monitoring_notification_channel.email[0].name] : []

  documentation {
    content = "Cloud SQL instance CPU utilization is above 80%"
  }
}

resource "google_monitoring_alert_policy" "sql_storage_low" {
  display_name = "${var.project_name}-sql-storage-low-${var.environment}"
  combiner     = "OR"
  enabled      = "true"

  conditions {
    display_name = "SQL Storage Low"
    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/disk/bytes_used\" AND resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.sql_instance_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.sql_storage_threshold
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.enable_email_notifications ? [google_monitoring_notification_channel.email[0].name] : []

  documentation {
    content = "Cloud SQL instance storage usage is above threshold"
  }
}

resource "google_monitoring_alert_policy" "sql_connections_high" {
  display_name = "${var.project_name}-sql-connections-high-${var.environment}"
  combiner     = "OR"
  enabled      = "true"

  conditions {
    display_name = "SQL Connections High"
    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/mysql/num_connections\" AND resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.sql_instance_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 50
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.enable_email_notifications ? [google_monitoring_notification_channel.email[0].name] : []

  documentation {
    content = "Cloud SQL instance has too many connections"
  }
}

# Alert Policies for Load Balancer
resource "google_monitoring_alert_policy" "lb_response_time_high" {
  count        = var.load_balancer_name != "" ? 1 : 0
  display_name = "${var.project_name}-lb-response-time-high-${var.environment}"
  combiner     = "OR"
  enabled      = "true"

  conditions {
    display_name = "Load Balancer Response Time High"
    condition_threshold {
      filter          = "metric.type=\"loadbalancing.googleapis.com/https/request_latencies\" AND resource.type=\"http_load_balancer\" AND resource.label.forwarding_rule_name=\"${var.load_balancer_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 2000
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_95"
      }
    }
  }

  notification_channels = var.enable_email_notifications ? [google_monitoring_notification_channel.email[0].name] : []

  documentation {
    content = "Load balancer response time is above 2 seconds"
  }
}

resource "google_monitoring_alert_policy" "lb_5xx_errors" {
  count        = var.load_balancer_name != "" ? 1 : 0
  display_name = "${var.project_name}-lb-5xx-errors-${var.environment}"
  combiner     = "OR"
  enabled      = "true"

  conditions {
    display_name = "Load Balancer 5XX Errors"
    condition_threshold {
      filter          = "metric.type=\"loadbalancing.googleapis.com/https/response_code_count\" AND resource.type=\"http_load_balancer\" AND resource.label.forwarding_rule_name=\"${var.load_balancer_name}\" AND metric.label.response_code_class=\"5xx\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
      }
    }
  }

  notification_channels = var.enable_email_notifications ? [google_monitoring_notification_channel.email[0].name] : []

  documentation {
    content = "Load balancer is experiencing 5XX errors"
  }
}

# Dashboard
resource "google_monitoring_dashboard" "main" {
  dashboard_json = jsonencode({
    displayName = "${var.project_name} Monitoring Dashboard - ${var.environment}"
    gridLayout = {
      columns = "2"
      widgets = [
        {
          title = "Frontend CPU Utilization"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                prometheusQuerySource = {
                  prometheusQuery = "compute_googleapis_com_instance_cpu_utilization{resource_type=\"gce_instance\", metadata_user_labels_instance_name=\"${var.frontend_instance_name}\"}"
                }
              }
              plotType = "LINE"
              legendTemplate = "{{metadata_user_labels_instance_name}}"
            }]
            timeshiftDuration = "0s"
            yAxis = {
              scale = "LINEAR"
            }
          }
        },
        {
          title = "Backend CPU Utilization"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                prometheusQuerySource = {
                  prometheusQuery = "compute_googleapis_com_instance_cpu_utilization{resource_type=\"gce_instance\", metadata_user_labels_instance_name=\"${var.backend_instance_name}\"}"
                }
              }
              plotType = "LINE"
              legendTemplate = "{{metadata_user_labels_instance_name}}"
            }]
            timeshiftDuration = "0s"
            yAxis = {
              scale = "LINEAR"
            }
          }
        },
        {
          title = "SQL CPU Utilization"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                prometheusQuerySource = {
                  prometheusQuery = "cloudsql_googleapis_com_database_cpu_utilization{resource_type=\"cloudsql_database\", resource_label_database_id=\"${var.sql_instance_name}\"}"
                }
              }
              plotType = "LINE"
              legendTemplate = "{{resource_label_database_id}}"
            }]
            timeshiftDuration = "0s"
            yAxis = {
              scale = "LINEAR"
            }
          }
        },
        {
          title = "SQL Storage Usage"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                prometheusQuerySource = {
                  prometheusQuery = "cloudsql_googleapis_com_database_disk_bytes_used{resource_type=\"cloudsql_database\", resource_label_database_id=\"${var.sql_instance_name}\"}"
                }
              }
              plotType = "LINE"
              legendTemplate = "{{resource_label_database_id}}"
            }]
            timeshiftDuration = "0s"
            yAxis = {
              scale = "LINEAR"
            }
          }
        }
      ]
    }
  })
}
