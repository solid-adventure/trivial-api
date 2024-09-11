locals {

  ttl_task_cron_name = "ttl-task-cron"

  ttl_task_cron_definition = {
    name      = "${local.name_prefix}-trivial-api-${local.ttl_task_cron_name}"
    image     = var.ecr_tag

   # delete entries older than 45 days with no register_item_id, preview_mode: false
    command   = ["rake", "tasks:cleanup_activity_entries[45, false]"]
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
        "dd_tags" : "env:${var.env},version:${local.datadog_version},ecs_service_name:${local.name_prefix}-${var.service_name}-${local.ttl_task_cron_name}"
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

resource "aws_ecs_task_definition" "trivial_api_ttl_task_cron_definition" {
  container_definitions = jsonencode(concat([
    local.ttl_task_cron_definition,
    local.agent_definition,
    local.log_router_definition,
  ]))
  family        = "${local.name_prefix}-${var.service_name}-${local.ttl_task_cron_name}"
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
  name       = "${local.name_prefix}-${var.service_name}-${local.ttl_task_cron_name}"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  # Will run daily at 6:15 UTC = 1:15 AM EST = 2:15 AM EDT
  schedule_expression = "cron(15 6 ? * * *)"

  target {
    arn = local.ecs_cluster_id
    # role that allows scheduler to start the task (explained later)
    role_arn = aws_iam_role.ttl_task_cron_role.arn

    ecs_parameters {
      # trimming the revision suffix here so that schedule always uses latest revision
      task_definition_arn = trimsuffix(aws_ecs_task_definition.trivial_api_ttl_task_cron_definition.arn, ":${aws_ecs_task_definition.trivial_api_ttl_task_cron_definition.revision}")
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