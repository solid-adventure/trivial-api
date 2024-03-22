locals {
  datadog_version = "${var.service_name}:${var.ecr_tag}"

  docker_labels = {
    "com.datadoghq.tags.env" : var.env,
    "com.datadoghq.tags.service" : var.service_name,
    "com.datadoghq.tags.version" : local.datadog_version
  }

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
        awslogs-group : "${local.name_prefix}-ecs-log",
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

  task_definition = {
      name      = "${local.name_prefix}-trivial-api"
      image     = var.ecr_tag
      cpu       = lookup(local.ecs_cpu, var.env, -1) - var.datadog_agent_cpu
      memory    = lookup(local.ecs_mem, var.env, -1) - var.datadog_agent_memory
      essential = true
      firelensConfiguration : null,
      logConfiguration : {
        logDriver : "awsfirelens",
        options : {
          "dd_message_key" : "log",
          "apikey" : var.datadog_api_key,
          "provider" : "ecs",
          "dd_source" : "aws",
          "dd_service" : var.service_name,
          "Host" : "http-intake.logs.datadoghq.com",
          "dd_tags" : "env:${var.env},version:${local.datadog_version},ecs_service_name:${aws_ecs_service.trivial_api_task-service.name}",
          "TLS" : "on",
          "Name" : "datadog"
        }
      },
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      secrets = [
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
          "name" : "MAILGUN_PASSWORD",
          "valueFrom" : "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}:mailgun_password::"
        },
      ]
      environment = [
        # TODO : remove once things are more stable, this env var should never go to prod
        {
          name : "SECRET_KEY_BASE",
          value : "whatdowesetthistoo"
        },
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
        },
        {
          name : "DD_ENV",
          value : var.env
        },
        {
          name : "DD_SERVICE",
          value : var.service_name
        },
        {
          name : "DD_VERSION",
          value : local.datadog_version
        }
      ]
    }
}

resource "aws_ecs_service" "trivial_api_task-service" {
  name                              = "${local.name_prefix}-trivial-api"
  cluster                           = local.ecs_cluster_id
  task_definition                   = aws_ecs_task_definition.trivial_api_task_definition.arn
  desired_count                     = lookup(local.desired_count, var.env, -1)
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = local.alb_target_group_arn
    container_port   = 3000
    container_name   = local.container_name
  }

  network_configuration {
    security_groups  = local.ecs_security_group_ids
    subnets          = local.ecs_subnet_ids
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "trivial_api_task_definition" {
  container_definitions = jsonencode(concat([
    local.task_definition,
  ]))
  family        = "${local.name_prefix}-trivial-api-task"
  network_mode  = "awsvpc"
  task_role_arn = local.ecs_task_role_arn

  requires_compatibilities = [
    "FARGATE",
  ]

  cpu                = lookup(local.ecs_cpu, var.env, -1)
  memory             = lookup(local.ecs_mem, var.env, -1)
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}