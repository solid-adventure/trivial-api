locals {
  cron_name = "cron-ttl-task"

  cron_ttl_task_definition = {
    name      = "${local.name_prefix}-trivial-api-${local.cron_name}"
    image     = var.ecr_tag

    # TEMP send "cleanup_activity_entries["60","false"]" to disable preview mode
    command   = ["rake", "tasks:cleanup_activity_entries["60"]"]
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
        "dd_tags" : "env:${var.env},version:${local.datadog_version},ecs_service_name:${local.name_prefix}-${var.service_name}-${local.cron_name}"
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
    secrets = concat(
      local.task_definition_secrets
    )
    environment = local.task_definition_env_vars
  }
}

resource "aws_ecs_task_definition" "trivial_api_cron_ttl_task_definition" {
  container_definitions = jsonencode(concat([
    local.cron_ttl_task_definition,
    local.agent_definition,
    local.log_router_definition,
  ]))
  family        = "${local.name_prefix}-${var.service_name}-${local.cron_name}"
  network_mode  = "awsvpc"
  task_role_arn = local.ecs_task_role_arn

  requires_compatibilities = [
    "FARGATE",
  ]

  cpu                = lookup(local.ecs_cpu, var.env, -1)
  memory             = lookup(local.ecs_mem, var.env, -1)
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_scheduler_schedule" "trivial_api_cron_ttl_task" {
  name       = "${local.name_prefix}-${var.service_name}-${local.cron_name}"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  # schedule_expression = "cron(0 6 ? * * *)" # run everyday at 6am UTC

  # TEMP run every 5 minutes
  schedule_expression = "cron(*/5 * ? * * *)"
  target {
    arn = local.ecs_cluster_id
    # role that allows scheduler to start the task (explained later)
    role_arn = aws_iam_role.new_period_cron_role.arn # Leaving this set to the new_period_role for now, which should have the same privelage

    ecs_parameters {
      # trimming the revision suffix here so that schedule always uses latest revision
      task_definition_arn = trimsuffix(aws_ecs_task_definition.trivial_api_cron_ttl_task_definition.arn, ":${aws_ecs_task_definition.trivial_api_cron_ttl_task_definition.revision}")
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