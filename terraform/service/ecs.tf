locals {
  task_definition = {
    name      = "${local.name_prefix}-trivial-api"
    image     = "${var.ecr_repo}:${var.image_tag}"
    cpu       = lookup(local.ecs_cpu, var.env, -1)
    memory    = lookup(local.ecs_mem, var.env, -1)
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
      }
    ]
    environment = [
      # TODO : remove once things are more stable, this env var should never go to prod
      {
        name : "ENABLE_REGISTRATION",
        value : "TRUE"
      },
      {
        name : "COOKIE_SIGNATURE",
        value : md5(var.env)
      },
      {
        name : "API_ENV",
        value : var.env
      },
      {
        name : "TRIVIAL_URL",
        value : "https://${local.trivial_api_service_domain}"
      },
      {
        name : "WHIPLASH_CLIENT_ID",
        value : var.core_oauth_client_id
      },
      {
        name : "WHIPLASH_CLIENT_SECRET",
        value : var.core_oauth_client_secret
      },

      {
        name : "WHIPLASH_BASE_URL",
        value : "https://${local.core_service_domain}"
      },
    ]
  }
}

resource "aws_ecs_service" "trivial_api_task-service" {
  name                   = "${local.name_prefix}-trivial-api"
  cluster                = local.ecs_cluster_id
  task_definition        = aws_ecs_task_definition.trivial_api_task_definition.arn
  desired_count          = lookup(local.desired_count, var.env, -1)
  launch_type            = "FARGATE"
  enable_execute_command = true

  load_balancer {
    target_group_arn = local.alb_target_group_arn
    container_port   = 80
    container_name   = local.container_name
  }

  network_configuration {
    security_groups  = local.ecs_security_group_ids
    subnets          = local.ecs_subnet_ids
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "trivial_api_task_definition" {
  container_definitions = jsonencode([local.task_definition])
  family                = "${local.name_prefix}-trivial-api-task"
  network_mode          = "awsvpc"
  task_role_arn         = local.ecs_task_role_arn

  requires_compatibilities = [
    "FARGATE",
  ]

  cpu                = lookup(local.ecs_cpu, var.env, -1)
  memory             = lookup(local.ecs_mem, var.env, -1)
  execution_role_arn = local.ecs_execution_role_arn
}