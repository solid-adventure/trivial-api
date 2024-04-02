data "aws_caller_identity" "current" {}

locals {
  aws_account_id             = data.aws_caller_identity.current.account_id
  container_name             = "${local.name_prefix}-trivial-api"
  enable_alt_dns             = data.terraform_remote_state.whiplash-regional.outputs.enable_alt_dns
  trivial_api_service_domain = data.terraform_remote_state.trivial-infra.outputs.trivial_api_service_domain
  trivial_ui_service_domain  = data.terraform_remote_state.trivial-infra.outputs.trivial_ui_service_domain
  core_service_domain        = local.enable_alt_dns == false ? data.terraform_remote_state.whiplash-regional.outputs.domain_names.core : data.terraform_remote_state.whiplash-regional.outputs.alt_domain_names.core

  desired_count = {
    canary : 2,
    stable : 2,
    sandbox : 2,
    production : 2
  }

  ecs_cpu = {
    canary : 512,
    stable : 512,
    sandbox : 512,
    production : 1024
  }

  ecs_mem = {
    canary : 1024,
    stable : 1024,
    sandbox : 1024,
    production : 2048
  }

  # Cleaner Remote Imports
  name_prefix            = data.terraform_remote_state.whiplash-regional.outputs.regional_prefix
  ecs_cluster_id         = data.terraform_remote_state.whiplash-regional.outputs.ecs_cluster_id
  ecs_security_group_ids = data.terraform_remote_state.whiplash-regional.outputs.ecs_security_group_ids
  ecs_subnet_ids         = data.terraform_remote_state.whiplash-regional.outputs.private_subnet_ids
  ecs_task_role_arn      = data.terraform_remote_state.whiplash-regional.outputs.ecs_task_role_arn

  alb_target_group_arn = data.terraform_remote_state.trivial-infra.outputs.trivial_api_alb_target_group_arn
  internal_alb_target_group_arn = data.terraform_remote_state.trivial-infra.outputs.internal_trivial_api_alb_target_group_arn

  trivial_postgres = {
    host     = data.terraform_remote_state.trivial-infra.outputs.trivial_database_host
    db       = data.terraform_remote_state.trivial-infra.outputs.trivial_database_db
    user     = data.terraform_remote_state.trivial-infra.outputs.trivial_database_user
    password = data.terraform_remote_state.trivial-infra.outputs.trivial_database_password
  }
}