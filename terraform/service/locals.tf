locals {
  container_name             = "${local.name_prefix}-trivial-api"
  trivial_api_service_domain = data.terraform_remote_state.trivial-infra.outputs.trivial_api_service_domain
  core_service_domain        = data.terraform_remote_state.whiplash-regional.outputs.domain_names.core

  desired_count = {
    canary : 2,
    stable : 2,
    sandbox : 2,
    production : 3
  }

  ecs_cpu = {
    canary : 256,
    stable : 256,
    sandbox : 256,
    production : 1024
  }

  ecs_mem = {
    canary : 512,
    stable : 512,
    sandbox : 512,
    production : 1024
  }

  # Cleaner Remote Imports
  name_prefix            = data.terraform_remote_state.whiplash-regional.outputs.regional_prefix
  ecs_cluster_id         = data.terraform_remote_state.whiplash-regional.outputs.ecs_cluster_id
  ecs_security_group_ids = data.terraform_remote_state.whiplash-regional.outputs.ecs_security_group_ids
  ecs_subnet_ids         = data.terraform_remote_state.whiplash-regional.outputs.private_subnet_ids
  ecs_task_role_arn      = data.terraform_remote_state.whiplash-regional.outputs.ecs_task_role_arn
  ecs_execution_role_arn = data.terraform_remote_state.whiplash-regional.outputs.ecs_execution_role_arn

  alb_target_group_arn = data.terraform_remote_state.trivial-infra.outputs.trivial_ui_alb_target_group_arn
}