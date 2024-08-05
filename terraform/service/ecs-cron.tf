locals {
  new_period_cron_name = "new-period-cron"

  kafka_secrets = [
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
  ]

  new_period_cron_task_definition = {
    name      = "${local.name_prefix}-trivial-api-${local.new_period_cron_name}"
    image     = var.ecr_tag
    command   = ["rake", "tasks:send_new_period_started_events"]
    cpu       = lookup(local.ecs_cpu, var.env, -1) - var.datadog_agent_cpu
    memory    = lookup(local.ecs_mem, var.env, -1) - var.datadog_agent_memory
    essential = true
    firelensConfiguration : null
    logConfiguration : {
      logDriver : "awsfirelens"
      options : {
        "dd_message_key" : "log"
        "apikey" : var.datadog_api_key
        "provider" : "ecs"
        "dd_source" : "aws"
        "dd_service" : var.service_name
        "Host" : "http-intake.logs.datadoghq.com"
        "dd_tags" : "env:${var.env},version:${local.datadog_version},ecs_service_name:${local.name_prefix}-${var.service_name}-${local.new_period_cron_name}"
        "TLS" : "on"
        "Name" : "datadog"
      }
    }
    portMappings = [
      {
        containerPort = 3000
        hostPort      = 3000
      }
    ]
    secrets     = concat(
      local.agent_definition_secrets,
      local.kafka_secrets
    )
    environment = local.agent_definition_env_vars
  }
}

resource "aws_ecs_task_definition" "trivial_api_new_period_cron_task_definition" {
  container_definitions = jsonencode(concat([
    local.new_period_cron_task_definition,
    local.agent_definition,
    local.log_router_definition,
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

resource "aws_scheduler_schedule" "trivial_api_new_period_cron" {
  name        = "${local.name_prefix}-${var.service_name}-${local.new_period_cron_name}"
  group_name  = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 5 * * *)" # run every 30 minutes

  target {
    arn      = local.ecs_cluster_id
    # role that allows scheduler to start the task (explained later)
    role_arn = aws_iam_role.new_period_cron_role.arn

    ecs_parameters {
      # trimming the revision suffix here so that schedule always uses latest revision
      task_definition_arn = trimsuffix(aws_ecs_task_definition.trivial_api_new_period_cron_task_definition.arn, ":${aws_ecs_task_definition.trivial_api_new_period_cron_task_definition.revision}")
      launch_type         = "FARGATE"
      network_configuration {
        security_groups = concat(
          local.ecs_security_group_ids,
          [
            local.allow_internal_vpc_traffic_security_group,
          ]
        )
        subnets          = local.ecs_subnet_ids
        assign_public_ip = false
      }
    }

    retry_policy {
      maximum_event_age_in_seconds = 300
      maximum_retry_attempts       = 10
    }
  }
}