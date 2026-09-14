locals {
  # da-terraform-modules has no tagged releases yet; module "source" strings
  # must be a static literal, so this commit (9ae2710901295ceefde378e9c9967bfdb331456f)
  # is hardcoded directly in each module block below rather than interpolated.
  common_tags = {
    Project = var.project_name
  }

  project_name                             = var.project_name
  aws_region                               = var.aws_region
  s3_models_store_bucket_name              = var.s3_models_store_bucket_name
  app_codepipeline_codestar_connection_arn = var.app_codepipeline_codestar_connection_arn
  app_github_repo_owner                    = var.app_github_repo_owner
  app_github_repo_name                     = var.app_github_repo_name
  app_container_name                       = "app"
  app_container_port                       = 8501
  app_task_memory                          = 2048
  app_task_cpu                             = 1024
  app_environment                          = []
  app_linux_parameters = {
    initProcessEnabled = false
  }
  app_awslogs_stream_prefix = "/app"
  app_entrypoint = [
    "/bin/bash", "-c",
    "aws s3 sync s3://${aws_s3_bucket.models_store.id} /code/models && streamlit run semantic_app.py --server.port=8501 --server.address=0.0.0.0"
  ]
  app_cloudfront_tls_certificate_arn  = var.app_cloudfront_tls_certificate_arn
  app_cloudfront_aliases              = var.app_cloudfront_aliases
  app_cloudfront_basic_auth_user_list = var.app_cloudfront_basic_auth_user_list
  app_alb_tls_certificate_arn         = var.app_alb_tls_certificate_arn

  # --- Beta app (caselaw-semantic-beta) ---
  beta_github_repo_owner                 = var.beta_github_repo_owner
  beta_github_repo_name                  = var.beta_github_repo_name
  beta_s3vectors_index_arn               = var.beta_s3vectors_index_arn
  beta_cloudfront_basic_auth_secret_name = var.beta_cloudfront_basic_auth_secret_name
  beta_alb_health_check_path             = var.beta_alb_health_check_path

  beta_container_name          = "beta"
  beta_container_port          = 8501
  beta_task_memory             = 2048
  beta_task_cpu                = 1024
  beta_base_url_path           = "beta"
  beta_cloudfront_path_pattern = "/beta*"
  beta_environment = [
    { name = "BASE_URL_PATH", value = local.beta_base_url_path },
    { name = "AWS_REGION", value = local.aws_region },
  ]
  beta_linux_parameters = {
    initProcessEnabled = false
  }
  beta_awslogs_stream_prefix = "/beta"
  # Beta queries the existing S3 Vectors index at runtime; vector upserts are
  # managed out of band rather than through an ECS startup sync.
  beta_entrypoint = [
    "/bin/bash", "-c",
    "streamlit run beta_app.py --server.port=8501 --server.address=0.0.0.0 --server.headless=true --server.baseUrlPath=${local.beta_base_url_path}"
  ]
}
