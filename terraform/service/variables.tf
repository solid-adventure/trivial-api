variable "env" {}
variable "aws_account" {}
variable "aws_region" {}

variable "contact" {}
variable "repo" {}
variable "service_name" {}
variable "ecr_tag" {}

variable "datadog_api_key" {}

variable "datadog_agent_cpu" {
  type    = number
  default = 10
}

variable "datadog_agent_memory" {
  type    = number
  default = 384
}