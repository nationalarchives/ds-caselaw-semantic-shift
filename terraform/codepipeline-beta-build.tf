module "beta_build_pipeline_codepipeline_role" {
  source = "git::https://github.com/nationalarchives/da-terraform-modules.git//iam_role?ref=9ae2710901295ceefde378e9c9967bfdb331456f"

  name = "${local.project_name}-${substr(sha512("beta-build-pipeline-codepipeline"), 0, 6)}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["codepipeline.amazonaws.com"]) }
  )
  tags = local.common_tags

  # All four policies are scoped either to the shared artifact bucket, the
  # shared CodeStar connection, or are fully generic (ECS/CodeDeploy actions
  # with Resource "*"), so the existing alpha policies are reused as-is.
  policy_attachments = {
    codepipeline_default    = aws_iam_policy.app_build_pipeline_codepipeline.arn
    ecs_deploy              = aws_iam_policy.app_build_pipeline_codepipeline_ecs_deploy.arn
    codestar_connection_use = aws_iam_policy.app_build_pipeline_codepipeline_codestar_connection.arn
    ecs_codedeploy          = aws_iam_policy.app_build_pipeline_codepipeline_codedeploy.arn
  }
}

resource "aws_codepipeline" "beta_build" {
  name = "${local.project_name}-beta-build"

  role_arn = module.beta_build_pipeline_codepipeline_role.role_arn

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
        FullRepositoryId = "${local.beta_github_repo_owner}/${local.beta_github_repo_name}"
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
        ProjectName = aws_codebuild_project.beta_build_pipeline.name
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
        ApplicationName     = aws_codedeploy_app.beta_blue_green.name
        DeploymentGroupName = aws_codedeploy_deployment_group.beta_blue_green.deployment_group_name
      }
    }
  }
}
