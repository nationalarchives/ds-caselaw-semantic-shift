module "beta_task_execution_ecr_pull_policy" {
  source = "git::https://github.com/nationalarchives/da-terraform-modules.git//iam_policy?ref=9ae2710901295ceefde378e9c9967bfdb331456f"

  name        = "${local.project_name}-${substr(sha512("beta-task-execution-ecr-pull"), 0, 6)}"
  description = "${local.project_name}-beta-task-execution-ecr-pull"
  policy_string = templatefile(
    "${path.root}/policies/ecr-pull.json.tpl",
    { ecr_repository_arn = module.beta_ecr.repository_arn }
  )
  tags = local.common_tags
}

module "beta_task_execution_role" {
  source = "git::https://github.com/nationalarchives/da-terraform-modules.git//iam_role?ref=9ae2710901295ceefde378e9c9967bfdb331456f"

  name = "${local.project_name}-${substr(sha512("beta-task-execution"), 0, 6)}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
  tags = local.common_tags

  # Cloudwatch logs policy is fully generic (Resource "*"), so the existing
  # alpha policy is reused rather than creating a duplicate for Beta.
  policy_attachments = {
    ecr_pull        = module.beta_task_execution_ecr_pull_policy.policy_arn
    cloudwatch_logs = aws_iam_policy.app_task_execution_cloudwatch_logs.arn
  }
}

# Read-only query access to the Beta S3 Vectors index used at search time.
# No PutVectors/write permission: offline embedding/upsert runs out of band,
# not from this web-facing task role.
module "beta_task_s3vectors_query_policy" {
  source = "git::https://github.com/nationalarchives/da-terraform-modules.git//iam_policy?ref=9ae2710901295ceefde378e9c9967bfdb331456f"

  name        = "${local.project_name}-${substr(sha512("beta-task-s3vectors-query"), 0, 6)}"
  description = "${local.project_name}-beta-task-s3vectors-query"
  policy_string = templatefile("${path.root}/policies/s3vectors-query-read.json.tpl", {
    index_arn = local.beta_s3vectors_index_arn
  })
  tags = local.common_tags
}

module "beta_task_role" {
  source = "git::https://github.com/nationalarchives/da-terraform-modules.git//iam_role?ref=9ae2710901295ceefde378e9c9967bfdb331456f"

  name = "${local.project_name}-${substr(sha512("beta-task"), 0, 6)}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
  tags = local.common_tags

  policy_attachments = {
    s3vectors_query = module.beta_task_s3vectors_query_policy.policy_arn
  }
}
