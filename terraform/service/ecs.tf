locals {
  task_definition = {
    name      = "${local.name_prefix}-trivial-api"
    image     = var.ecr_tag
    cpu       = lookup(local.ecs_cpu, var.env, -1)
    memory    = lookup(local.ecs_mem, var.env, -1)
    essential = true
    logConfiguration = {
      logDriver = "awslogs",
      options: {
        awslogs-group: "${local.name_prefix}-ecs-logs",
        awslogs-region: "us-east-1",
        awslogs-stream-prefix: "ecs/${var.service_name}"
      }
    }
    portMappings = [
      {
        containerPort = 3000
        hostPort      = 3000
      }
    ]
#    secrets = [
#      {
#      "name": "WHIPLASH_CLIENT_ID",
#      "valueFrom": "${data.aws_secretsmanager_secret.secrets.arn}:whiplash_client_id::"
#      },
#      {
#        "name": "WHIPLASH_CLIENT_SECRET",
#        "valueFrom": "${data.aws_secretsmanager_secret.secrets.arn}:whiplash_client_secret::"
#      },
#      {
#        "name": "CLIENT_SECRET",
#        "valueFrom": "${data.aws_secretsmanager_secret.secrets.arn}:client_secret::"
#      },
#      {
#        "name": "CLIENT_KEY",
#        "valueFrom": "${data.aws_secretsmanager_secret.secrets.arn}:client_key::"
#      },
#      {
#        "name": "MAILGUN_PASSWORD",
#        "valueFrom": "${data.aws_secretsmanager_secret.secrets.arn}:mailgun_password::"
#      },
#    ]
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
        name: "TRIVIAL_UI_URL",
        value: local.trivial_ui_service_domain
      }
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
  container_definitions = jsonencode([local.task_definition])
  family                = "${local.name_prefix}-trivial-api-task"
  network_mode          = "awsvpc"
  task_role_arn         = local.ecs_task_role_arn

  requires_compatibilities = [
    "FARGATE",
  ]

  cpu                = lookup(local.ecs_cpu, var.env, -1)
  memory             = lookup(local.ecs_mem, var.env, -1)
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}