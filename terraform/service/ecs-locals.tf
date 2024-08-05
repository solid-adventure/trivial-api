locals {
  datadog_version = "${var.service_name}:${var.ecr_tag}"

  docker_labels = {
    "com.datadoghq.tags.env" : var.env,
    "com.datadoghq.tags.service" : var.service_name,
    "com.datadoghq.tags.version" : local.datadog_version
  }

  agent_definition_secrets = [
    {
      name : "KAFKA_USERNAME",
      valueFrom : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:KAFKA_USERNAME::"
    },
    {
      name : "KAFKA_PASSWORD",
      valueFrom : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:KAFKA_PASSWORD::"
    },
    {
      name : "KAFKA_BOOTSTRAP_SERVERS",
      valueFrom : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:KAFKA_BOOTSTRAP_SERVERS::"
    },
    {
      name : "KAFKA_TOPIC",
      valueFrom : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:KAFKA_TOPIC::"
    },
    {
      name : "KAFKA_NAMESPACE",
      valueFrom : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:KAFKA_NAMESPACE::"
    },
    {
      "name" : "WHIPLASH_CLIENT_ID",
      "valueFrom" : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:whiplash_client_id::"
    },
    {
      "name" : "WHIPLASH_CLIENT_SECRET",
      "valueFrom" : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:whiplash_client_secret::"
    },
    {
      "name" : "CLIENT_SECRET",
      "valueFrom" : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:client_secret::"
    },
    {
      "name" : "CLIENT_KEYS",
      "valueFrom" : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:client_keys::"
    },
    {
      "name" : "MAILGUN_SMTP_PASSWORD",
      "valueFrom" : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:mailgun_password::"
    },
  ]

  agent_definition_env_vars = [
    {
      name : "RAILS_ENV",
      value : "production"
    },
    {
      name : "RAILS_LOG_TO_STDOUT",
      value : "true"
    },
    {
      name : "POSTGRES_HOST",
      value : local.trivial_postgres.host
    },
    {
      name : "POSTGRES_DATABASE",
      value : local.trivial_postgres.db
    },
    {
      name : "POSTGRES_USER",
      value : local.trivial_postgres.user
    },
    {
      name : "POSTGRES_PASSWORD",
      value : local.trivial_postgres.password
    },
    {
      name : "EXTERNAL_HOST",
      value : local.trivial_api_service_domain
    },
    {
      name : "MAILGUN_DOMAIN",
      value : "whiplash.com"
    },
    {
      name : "MAILGUN_SMTP_LOGIN",
      value : "billingapp@mg.whiplash.com"
    },
    {
      name : "MAILGUN_SMTP_PORT",
      value : "587"
    },
    {
      name : "MAILGUN_SMTP_SERVER",
      value : "smtp.mailgun.org"
    },
    {
      name : "DEFAULT_URL_HOST",
      value : "https://${local.trivial_api_service_domain}"
    },
    {
      name : "DEFAULT_URL_PORT",
      value : "443"
    },
    {
      name : "WHIPLASH_BASE_URL",
      value : "https://${local.core_service_domain}"
    },
    {
      name : "TRIVIAL_UI_URL",
      value : local.trivial_ui_service_domain
    }
  ]


  log_router_definition = merge(
    local.docker_labels,
    {
      # For some reason explicitly adding user: "0" prevents accidental changes on apply. I have no idea why it works or what it does. Don't remove it.
      user : "0",
      "name" : "${local.container_name}-datadog-log-router"
      "image" : "amazon/aws-for-fluent-bit",
      "logConfiguration" : null,
      "firelensConfiguration" : {
        "type" : "fluentbit",
        "options" : {
          "enable-ecs-log-metadata" : "true"
        }
      }
    }
  )

  agent_definition = {
    "image" : "public.ecr.aws/datadog/agent:latest",
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        awslogs-group : "${local.name_prefix}-ecs-logs",
        "awslogs-region" : var.aws_region,
        # Do we need this line?
        "awslogs-stream-prefix" : "ecs/${var.service_name}"
      }
    },
    "cpu" : var.datadog_agent_cpu,
    "memory" : var.datadog_agent_memory,
    "mountPoints" : [],
    "portMappings" : [
      {
        "hostPort" : 8126,
        "protocol" : "tcp",
        "containerPort" : 8126
      }
    ],
    "environment" : [
      {
        "name" : "ECS_FARGATE",
        "value" : "true"
      },
      {
        "name" : "DD_PROCESS_AGENT_ENABLED",
        "value" : "true"
      },
      {
        "name" : "DD_DOGSTATSD_NON_LOCAL_TRAFFIC",
        "value" : "true"
      },
      {
        "name" : "DD_APM_NON_LOCAL_TRAFFIC",
        "value" : "true"
      },
      {
        "name" : "DD_APM_ENABLED",
        "value" : "true"
      },
      {
        "name" : "DD_ENV",
        "value" : var.env
      },
      {
        "name" : "DD_SERVICE",
        "value" : var.service_name
      },
      {
        "name" : "DD_VERSION",
        "value" : local.datadog_version
      },
      {
        "name" : "DD_API_KEY",
        "value" : var.datadog_api_key
      }
    ],
    "name" : "${local.container_name}-datadog-agent"
  }
}