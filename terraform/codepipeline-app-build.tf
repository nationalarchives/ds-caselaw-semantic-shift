resource "aws_iam_role" "app_build_pipeline_codepipeline" {
  name        = "${local.project_name}-${substr(sha512("app-build-pipeline-codepipeline"), 0, 6)}"
  description = "${local.project_name}-app-build-pipeline-codepipeline"

  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["codepipeline.amazonaws.com"]) }
  )
}
resource "aws_iam_policy" "app_build_pipeline_codepipeline" {
  name        = "${local.project_name}-${substr(sha512("app-build-pipeline-codepipeline"), 0, 6)}"
  description = "${local.project_name}-app-build-pipeline-codepipeline"
  policy = templatefile(
    "${path.root}/policies/codepipeline-default.json.tpl",
    { artifact_bucket_arn = aws_s3_bucket.app_build_pipeline_artifact_store.arn }
  )
}

resource "aws_iam_role_policy_attachment" "app_build_pipeline_codepipeline" {
  role       = aws_iam_role.app_build_pipeline_codepipeline.name
  policy_arn = aws_iam_policy.app_build_pipeline_codepipeline.arn
}

resource "aws_iam_policy" "app_build_pipeline_codepipeline_ecs_deploy" {
  name        = "${local.project_name}-${substr(sha512("app-build-pipeline-codepipeline-ecs-deploy"), 0, 6)}"
  description = "${local.project_name}-app-build-pipeline-codepipeline-ecs-deploy"
  policy = templatefile(
    "${path.root}/policies/codepipeline-ecs-deploy.json.tpl", {}
  )
}

resource "aws_iam_role_policy_attachment" "app_build_pipeline_codepipeline_ecs_deploy" {
  role       = aws_iam_role.app_build_pipeline_codepipeline.name
  policy_arn = aws_iam_policy.app_build_pipeline_codepipeline_ecs_deploy.arn
}

resource "aws_iam_policy" "app_build_pipeline_codepipeline_codestar_connection" {
  name        = "${local.project_name}-${substr(sha512("app-build-pipeline-codepipeline-codestar-connection"), 0, 6)}"
  description = "${local.project_name}-app-build-pipeline-codepipeline-codestar-connection"
  policy = templatefile(
    "${path.root}/policies/codestar-connection-use.json.tpl",
    { codestar_connection_arn = local.app_codepipeline_codestar_connection_arn }
  )
}

resource "aws_iam_role_policy_attachment" "app_build_pipeline_codepipeline_codestar_connection" {
  role       = aws_iam_role.app_build_pipeline_codepipeline.name
  policy_arn = aws_iam_policy.app_build_pipeline_codepipeline_codestar_connection.arn
}

resource "aws_iam_policy" "app_build_pipeline_codepipeline_codedeploy" {
  name        = "${local.project_name}-${substr(sha512("app-build-pipeline-codepipeline-codedeploy"), 0, 6)}"
  description = "${local.project_name}-app-build-pipeline-codepipeline-codedeploy"
  policy = templatefile(
    "${path.root}/policies/codepipeline-ecs-codedeploy.json.tpl", {}
  )
}

resource "aws_iam_role_policy_attachment" "app_build_pipeline_codepipeline_codedeploy" {
  role       = aws_iam_role.app_build_pipeline_codepipeline.name
  policy_arn = aws_iam_policy.app_build_pipeline_codepipeline_codedeploy.arn
}

resource "aws_codepipeline" "app_build" {
  name = "${local.project_name}-app-build"

  role_arn = aws_iam_role.app_build_pipeline_codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.app_build_pipeline_artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        ConnectionArn    = local.app_codepipeline_codestar_connection_arn
        FullRepositoryId = "${local.app_github_repo_owner}/${local.app_github_repo_name}"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["appspec"]

      configuration = {
        ProjectName = aws_codebuild_project.app_build_pipeline.name
      }
    }
  }

  stage {
    name = "Deploy-Blue-Green"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["appspec"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.ecs_service_blue_green.name
        DeploymentGroupName = aws_codedeploy_deployment_group.ecs_service_blue_green.deployment_group_name
      }
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.app_build_pipeline_codepipeline,
    aws_iam_role_policy_attachment.app_build_pipeline_codepipeline_codestar_connection,
    aws_iam_role_policy_attachment.app_build_pipeline_codepipeline_codedeploy,
  ]
}
