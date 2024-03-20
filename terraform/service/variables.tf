variable "env" {}
variable "aws_account" {}
variable "aws_region" {}

variable "contact" {}
variable "repo" {}
variable "service_name" {}
variable "ecr_repo" {}
variable "image_tag" {}

# Service Specific Variables. These should be set either for CI or in the vars files depending on sensitivity.
variable "core_oauth_client_id" {
  sensitive = true
}
variable "core_oauth_client_secret" {
  sensitive = true
}
variable "mailgun_password" {
  sensitive = true
}
variable "jwt_private_key" {
  sensitive = true
}
variable "client_keys" {
  sensitive = true
}