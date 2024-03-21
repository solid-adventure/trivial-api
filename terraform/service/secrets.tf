data "aws_secretsmanager_secret" "trivial_api_secrets" {
  name = var.service_name
}