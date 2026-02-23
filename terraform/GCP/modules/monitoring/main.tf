# Monitoring Module for GCP

# Log Sinks for Compute Instances
resource "google_logging_project_sink" "frontend_logs" {
  name        = "${var.project_name}-frontend-logs-sink-${var.environment}"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.project_name}_frontend_logs_${var.environment}"
  
  filter = "resource.type=\"gce_instance\" AND resource.labels.instance_id=~\"${var.frontend_mig_name}.*\""
  
  unique_writer_identity = true
}

resource "google_logging_project_sink" "backend_logs" {
  name        = "${var.project_name}-backend-logs-sink-${var.environment}"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.project_name}_backend_logs_${var.environment}"
  
  filter = "resource.type=\"gce_instance\" AND resource.labels.instance_id=~\"${var.backend_mig_name}.*\""
  
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
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\" AND metadata.system_labels.instance_group=\"${var.frontend_mig_name}\""
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
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\" AND metadata.system_labels.instance_group=\"${var.backend_mig_name}\""
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

resource "google_monitoring_alert_policy" "sql_storage_high_pct" {
  display_name = "${var.project_name}-sql-storage-high-pct-${var.environment}"
  combiner     = "OR"
  enabled      = "true"

  conditions {
    display_name = "SQL Storage Usage > 80%"
    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/disk/utilization\" AND resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.sql_instance_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.sql_storage_threshold_pct
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
      filter          = "metric.type=\"cloudsql.googleapis.com/database/network/connections\" AND resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.sql_instance_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.max_connections
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
      filter          = "metric.type=\"loadbalancing.googleapis.com/https/backend_latencies\" AND resource.type=\"https_lb_rule\" AND resource.label.backend_target_name=\"${var.frontend_backend_service}\""
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
      filter          = "metric.type=\"loadbalancing.googleapis.com/https/request_count\" AND resource.type=\"https_lb_rule\" AND resource.label.backend_target_name=\"${var.frontend_backend_service}\" AND metric.label.response_code_class=5"
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

resource "google_monitoring_uptime_check_config" "frontend_uptime" {
  display_name = "${var.project_name}-frontend-uptime-${var.environment}"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path = "/"
    port = "80"
    use_ssl = false
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.load_balancer_ip
    }
  }
}

resource "google_monitoring_alert_policy" "uptime_alert" {
  display_name = "Uptime Check Failure: Frontend"
  combiner     = "OR"
  conditions {
    display_name = "Uptime check failed"
    condition_threshold {
      filter     = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.frontend_uptime.uptime_check_id}\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = 1
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_COUNT_FALSE"
      }
    }
  }
  notification_channels = var.enable_email_notifications ? [google_monitoring_notification_channel.email[0].name] : []
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
                timeSeriesQueryLanguage = "fetch gce_instance | metric 'compute.googleapis.com/instance/cpu/utilization' | filter (metadata.system_labels.instance_group == '${var.frontend_mig_name}') | align mean(5m) | every 5m"
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
                timeSeriesQueryLanguage = "fetch gce_instance | metric 'compute.googleapis.com/instance/cpu/utilization' | filter (metadata.system_labels.instance_group == '${var.backend_mig_name}') | align mean(5m) | every 5m"
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
                timeSeriesQueryLanguage = "fetch cloudsql_database | metric 'cloudsql.googleapis.com/database/cpu/utilization' | filter (resource.database_id == '${var.sql_instance_name}') | align mean(5m) | every 5m"
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
          title = "SQL Storage Usage (MQL)",
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesQueryLanguage = "fetch cloudsql_database | metric 'cloudsql.googleapis.com/database/disk/utilization' | filter (resource.database_id == '${var.sql_instance_name}') | align mean(5m) | every 5m"
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
          title = "Frontend Availability (Uptime)",
          scorecard = {
            timeSeriesQuery = {
              timeSeriesQueryLanguage = "fetch uptime_url | metric 'monitoring.googleapis.com/uptime_check/check_passed' | filter (metric.check_id == '${google_monitoring_uptime_check_config.frontend_uptime.uptime_check_id}') | align mean(1m) | every 1m"
            }
          }
        },
        {
          title = "LB Response Time (95%) - Latency",
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesQueryLanguage = "fetch http_load_balancer | metric 'loadbalancing.googleapis.com/https/request_latencies' | filter (metric.forwarding_rule_name == '${var.frontend_backend_service}') | align delta(1m) | every 1m | group_by [], [value_request_latencies_aggregate: aggregate(value.request_latencies)] | p95"
              }
              plotType = "LINE"
              legendTemplate = "Latency (95th percentile)"
            }]
            timeshiftDuration = "0s"
            yAxis = {
              label = "ms",
              scale = "LINEAR"
            }
          }
        }
      ]
    }
  })
}

# BigQuery Dataset for sinks
resource "google_bigquery_dataset" "instance_logs" {
  dataset_id                  = "compute_instance_logs_${var.environment}"
  friendly_name               = "Instance Logs"
  description                 = "Logs from GCE instances"
  location                    = "US"
  delete_contents_on_destroy  = true # Should be 'false' in Production
}

locals {
  log_sink_identities = [
    google_logging_project_sink.frontend_logs.writer_identity,
    google_logging_project_sink.backend_logs.writer_identity,
    google_logging_project_sink.ansible_logs.writer_identity
  ]
}

# Write access to the BigQuery dataset for all log sinks
resource "google_project_iam_member" "log_sink_bigquery_editor" {
  count = length(local.log_sink_identities)

  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = local.log_sink_identities[count.index]
}

# Grant BigQuery data editor role to all log sink identities
resource "google_project_iam_member" "log_sinks_bq_editor" {
  count = length(local.log_sink_identities)

  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = local.log_sink_identities[count.index]
}
