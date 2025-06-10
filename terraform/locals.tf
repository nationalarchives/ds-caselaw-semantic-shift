locals {
  project_name                             = var.project_name
  aws_region                               = var.aws_region
  aws_account_id                           = data.aws_caller_identity.current.account_id
  s3_models_store_bucket_name              = var.s3_models_store_bucket_name
  app_codepipeline_codestar_connection_arn = var.app_codepipeline_codestar_connection_arn
  app_github_repo_owner                    = var.app_github_repo_owner
  app_github_repo_name                     = var.app_github_repo_name
  app_entrypoint = [
    "/bin/bash", "-c",
    "aws s3 sync s3://${aws_s3_bucket.models_store.id} /code/models && streamlit run semantic_app.py --server.port=80 --server.address=0.0.0.0"
  ]
  app_cloudfront_tls_certificate_arn  = var.app_cloudfront_tls_certificate_arn
  app_cloudfront_aliases              = var.app_cloudfront_aliases
  app_cloudfront_origin_domain_name   = var.app_cloudfront_origin_domain_name
  app_cloudfront_basic_auth_user_list = var.app_cloudfront_basic_auth_user_list
}
