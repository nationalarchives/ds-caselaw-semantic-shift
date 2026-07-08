resource "aws_iam_role" "app_build_pipeline_codebuild" {
  name        = "${local.project_name}-${substr(sha512("app-build-pipeline-codebuild"), 0, 6)}"
  description = "${local.project_name}-app-build-pipeline-codebuild"

  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["codebuild.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "app_build_pipeline_codebuild" {
  name        = "${local.project_name}-${substr(sha512("app-build-pipeline-codebuild"), 0, 6)}"
  description = "${local.project_name}-app-build-pipeline-codebuild"
  policy = templatefile(
    "${path.root}/policies/codebuild-default.json.tpl",
    { artifact_bucket_arn = aws_s3_bucket.app_build_pipeline_artifact_store.arn }
  )
}

resource "aws_iam_role_policy_attachment" "app_build_pipeline_codebuild" {
  role       = aws_iam_role.app_build_pipeline_codebuild.name
  policy_arn = aws_iam_policy.app_build_pipeline_codebuild.arn
}

resource "aws_iam_policy" "app_build_pipeline_codebuild_blue_green" {
  name        = "${local.project_name}-${substr(sha512("app-build-pipeline-codebuild-blue-green"), 0, 6)}"
  description = "${local.project_name}-app-build-pipeline-codebuild-blue-green"
  policy = templatefile(
    "${path.root}/policies/codebuild-ecs-blue-green.json.tpl", {}
  )
}

resource "aws_iam_role_policy_attachment" "app_build_pipeline_codebuild_blue_green" {
  role       = aws_iam_role.app_build_pipeline_codebuild.name
  policy_arn = aws_iam_policy.app_build_pipeline_codebuild_blue_green.arn
}

resource "aws_iam_policy" "app_build_pipeline_codebuild_ecr_push" {
  name        = "${local.project_name}-${substr(sha512("app-build-pipeline-codebuild-ecr-push"), 0, 6)}"
  description = "${local.project_name}-app-build-pipeline-codebuild-ecr-push"
  policy = templatefile(
    "${path.root}/policies/ecr-push.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.app.arn }
  )
}

resource "aws_iam_role_policy_attachment" "app_build_pipeline_codebuild_ecr_push" {
  role       = aws_iam_role.app_build_pipeline_codebuild.name
  policy_arn = aws_iam_policy.app_build_pipeline_codebuild_ecr_push.arn
}

resource "aws_codebuild_project" "app_build_pipeline" {
  name          = "${local.project_name}-app-build-pipeline"
  build_timeout = "60"
  service_role  = aws_iam_role.app_build_pipeline_codebuild.arn

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
    type      = "CODEPIPELINE"
    buildspec = templatefile("${path.root}/buildspecs/app.json.tpl", {
      repository_url         = aws_ecr_repository.app.repository_url
      container_name         = local.app_container_name
      task_definition_family = aws_ecs_task_definition.app.family
      task_role_arn          = aws_iam_role.app_task.arn
      execution_role_arn     = aws_iam_role.app_task_execution.arn
      task_memory            = local.app_task_memory
      task_cpu               = local.app_task_cpu
      cloudwatch_log_group   = aws_cloudwatch_log_group.app.name
      awslogs_stream_prefix  = local.app_awslogs_stream_prefix
      environment_json       = jsonencode(local.app_environment)
      linux_parameters_json  = jsonencode(local.app_linux_parameters)
      app_entrypoint_json    = jsonencode(local.app_entrypoint)
      app_container_port     = local.app_container_port
    })
  }

  depends_on = [
    aws_iam_role_policy_attachment.app_build_pipeline_codebuild,
    aws_iam_role_policy_attachment.app_build_pipeline_codebuild_blue_green,
    aws_iam_role_policy_attachment.app_build_pipeline_codebuild_ecr_push,
  ]
}
