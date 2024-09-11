resource "aws_iam_role" "ttl_task_cron_role" {
  name = "ttl-task-cron-scheduler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["scheduler.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ttl_task_cron_role_policy_attachment" {
  policy_arn = aws_iam_policy.ttl_task_scheduler.arn
  role       = aws_iam_role.ttl_task_cron_role.name
}

resource "aws_iam_policy" "ttl_task_scheduler" {
  name = "ttl-task-cron-scheduler-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask"
        ]
        Resource = [
          aws_ecs_task_definition.trivial_api_new_period_cron_task_definition.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ]
        Resource = [local.ecs_task_role_arn, aws_iam_role.ecs_task_execution_role.arn]
      },
    ]
  })
}