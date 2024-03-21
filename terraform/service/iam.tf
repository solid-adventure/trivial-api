resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.service_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "ecs_task_iam_policy" {
  name        = "${var.service_name}-ecs-execution-policy"
  path        = "/"
  description = "${var.service_name} ECS Execution Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = [
          data.aws_secretsmanager_secret.trivial_api_secrets.arn,
          "${data.aws_secretsmanager_secret.trivial_api_secrets.arn}*"
        ]
      },
      {
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "iam:PassRole",
          "ecs:*",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecs_task_policy_to_role" {
  role =  aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_iam_policy.arn
}

