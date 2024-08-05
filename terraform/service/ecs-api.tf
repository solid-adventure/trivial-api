locals {
  api_task_definition = {
    name      = "${local.name_prefix}-trivial-api"
    image     = var.ecr_tag
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
        "dd_tags" : "env:${var.env},version:${local.datadog_version},ecs_service_name:${local.name_prefix}-${var.service_name}"
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
    secrets     = local.agent_definition_secrets
    environment = local.agent_definition_env_vars
  }
}

resource "aws_ecs_service" "trivial_api_task-service" {
  name                              = "${local.name_prefix}-${var.service_name}"
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

  load_balancer {
    target_group_arn = local.internal_alb_target_group_arn
    container_port   = 3000
    container_name   = local.container_name
  }

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

resource "aws_ecs_task_definition" "trivial_api_task_definition" {
  container_definitions = jsonencode(concat([
    local.api_task_definition,
    local.agent_definition,
    local.log_router_definition
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
