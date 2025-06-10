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
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.aws_account_id
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = "app"
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.app.name
    }

    environment_variable {
      name  = "REPOSITORY_URL"
      value = aws_ecr_repository.app.repository_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = templatefile("${path.root}/buildspecs/app.json.tpl", {})
  }

  depends_on = [
    aws_iam_role_policy_attachment.app_build_pipeline_codebuild,
    aws_iam_role_policy_attachment.app_build_pipeline_codebuild_ecr_push,
  ]
}
