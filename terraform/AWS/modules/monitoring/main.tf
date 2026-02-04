# CloudWatch Log Groups for EC2 instances
resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}-frontend"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-frontend-logs-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}-backend"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-backend-logs-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "ansible_logs" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}-ansible"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-ansible-logs-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

locals {
  ec2_instances = {
    frontend = {
      id   = var.frontend_instance_id
      name = "frontend"
    }
    backend = {
      id   = var.backend_instance_id
      name = "backend"
    }
    /*
    Uncomment this block when monitor the ansible instance is needed
    ansible = {
      id   = var.ansible_instance_id
      name = "ansible"
    }
    */
  }
}

# SNS Topic for notifications (conditionally created)
resource "aws_sns_topic" "monitoring_alerts" {
  count = var.enable_email_notifications ? 1 : 0
  name  = "${var.project_name}-monitoring-alerts-${var.environment}"

  tags = {
    Name        = "${var.project_name}-monitoring-alerts"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_sns_topic_subscription" "email_subscription" {
  count     = var.enable_email_notifications && var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.monitoring_alerts[0].arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# CloudWatch Alarms for EC2 instances using for_each
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  for_each = local.ec2_instances

  alarm_name          = "${var.project_name}-${each.value.name}-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization for ${each.value.name} instance"

  dimensions = {
    InstanceId = each.value.id
  }

  alarm_actions = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []
  ok_actions    = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []

  tags = {
    Name        = "${var.project_name}-${each.value.name}-cpu-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []
  ok_actions    = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []

  tags = {
    Name        = "${var.project_name}-rds-cpu-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.project_name}-rds-storage-low-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1073741824" # 1GB in bytes
  alarm_description   = "This metric monitors RDS free storage space"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []
  ok_actions    = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []

  tags = {
    Name        = "${var.project_name}-rds-storage-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${var.project_name}-rds-connections-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This metric monitors RDS database connections"
  
  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []
  ok_actions    = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []

  tags = {
    Name        = "${var.project_name}-rds-connections-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Alarms for ALB
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 5XX errors"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []
  ok_actions    = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []

  tags = {
    Name    = "${var.project_name}-alb-5xx-alarm"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${var.project_name}-alb-high-response-time-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors high ALB target response time"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []
  ok_actions    = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []

  tags = {
    Name    = "${var.project_name}-alb-response-alarm"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors ALB unhealthy host count"

  dimensions = {
    TargetGroup = var.alb_target_group_arn_suffix
  }

  alarm_actions = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []
  ok_actions    = var.enable_email_notifications ? [aws_sns_topic.monitoring_alerts[0].arn] : []
  
  tags = {
    Name        = "${var.project_name}-alb-health-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "monitoring_dashboard" {
  dashboard_name = "${var.project_name}-monitoring-dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      # EC2 CPU Utilization
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            for instance_name, instance_data in local.ec2_instances : [
              "AWS/EC2", "CPUUtilization", "InstanceId", instance_data.id
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 CPU Utilization"
          period  = 300
        }
      },
      # RDS Metrics
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id],
            [".", "FreeStorageSpace", ".", "."],
            [".", "DatabaseConnections", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS Performance Metrics"
          period  = 300
        }
      },
      # ALB Metrics
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "UnHealthyHostCount", "TargetGroup", var.alb_target_group_arn_suffix]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ALB Performance Metrics"
          period  = 300
        }
      },
      # Alarm Status
      {
        type   = "alarm"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          alarms = [
            aws_cloudwatch_metric_alarm.ec2_cpu_high["frontend"].alarm_name,
            aws_cloudwatch_metric_alarm.ec2_cpu_high["backend"].alarm_name,
            aws_cloudwatch_metric_alarm.ec2_cpu_high["ansible"].alarm_name,
            aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name,
            aws_cloudwatch_metric_alarm.rds_storage_low.alarm_name,
            aws_cloudwatch_metric_alarm.rds_connections_high.alarm_name,
            aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name,
            aws_cloudwatch_metric_alarm.alb_target_response_time.alarm_name,
            aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name
          ]
          title = "Alarm Status"
        }
      }
    ]
  })
}
