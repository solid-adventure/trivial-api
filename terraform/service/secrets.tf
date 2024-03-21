data "aws_secretsmanager_secret" "secrets" {
  name = "trivial-api"
}
#
#data "aws_secretsmanager_secret_version" "current" {
#  secret_id = data.aws_secretsmanager_secret.secrets.id
#}
#
#data "aws_secretsmanager_secrets" "example" {
#  filter {
#    name   = "name"
#    values = ["example"]
#  }
#}