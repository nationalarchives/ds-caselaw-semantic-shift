module "beta_build_pipeline_codebuild_ecr_push_policy" {
  source = "git::https://github.com/nationalarchives/da-terraform-modules.git//iam_policy?ref=9ae2710901295ceefde378e9c9967bfdb331456f"

  name        = "${local.project_name}-${substr(sha512("beta-build-pipeline-codebuild-ecr-push"), 0, 6)}"
  description = "${local.project_name}-beta-build-pipeline-codebuild-ecr-push"
  policy_string = templatefile(
    "${path.root}/policies/ecr-push.json.tpl",
    { ecr_repository_arn = module.beta_ecr.repository_arn }
  )
  tags = local.common_tags
}

# Reuses the existing alpha build-pipeline role's other policies: they are
# scoped to the shared artifact bucket or are fully generic, so only the
# ECR-push permission (scoped to the Beta repository) needs to be new.
module "beta_build_pipeline_codebuild_role" {
  source = "git::https://github.com/nationalarchives/da-terraform-modules.git//iam_role?ref=9ae2710901295ceefde378e9c9967bfdb331456f"

  name = "${local.project_name}-${substr(sha512("beta-build-pipeline-codebuild"), 0, 6)}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["codebuild.amazonaws.com"]) }
  )
  tags = local.common_tags

  policy_attachments = {
    codebuild_default = aws_iam_policy.app_build_pipeline_codebuild.arn
    ecs_blue_green    = aws_iam_policy.app_build_pipeline_codebuild_blue_green.arn
    ecr_push          = module.beta_build_pipeline_codebuild_ecr_push_policy.policy_arn
  }
}

resource "aws_codebuild_project" "beta_build_pipeline" {
  name          = "${local.project_name}-beta-build-pipeline"
  build_timeout = "60"
  service_role  = module.beta_build_pipeline_codebuild_role.role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.root}/buildspecs/beta.json.tpl", {
      repository_url         = module.beta_ecr.repository_url
      container_name         = local.beta_container_name
      task_definition_family = aws_ecs_task_definition.beta.family
      task_role_arn          = module.beta_task_role.role_arn
      execution_role_arn     = module.beta_task_execution_role.role_arn
      task_memory            = local.beta_task_memory
      task_cpu               = local.beta_task_cpu
      cloudwatch_log_group   = aws_cloudwatch_log_group.beta.name
      awslogs_stream_prefix  = local.beta_awslogs_stream_prefix
      environment_json       = jsonencode(local.beta_environment)
      linux_parameters_json  = jsonencode(local.beta_linux_parameters)
      app_entrypoint_json    = jsonencode(local.beta_entrypoint)
      app_container_port     = local.beta_container_port
    })
  }
}
