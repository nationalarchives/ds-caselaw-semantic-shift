resource "aws_iam_role" "app_task_execution" {
  name        = "${local.project_name}-${substr(sha512("app-task-execution"), 0, 6)}"
  description = "${local.project_name}-app-task-execution"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "app_task_execution_ecr_pull" {
  name        = "${local.project_name}-${substr(sha512("app-task-execution-ecr-pull"), 0, 6)}"
  description = "${local.project_name}-app-task-execution-ecr-pull"
  policy = templatefile(
    "${path.root}/policies/ecr-pull.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.app.arn }
  )
}

resource "aws_iam_role_policy_attachment" "app_task_execution_ecr_pull" {
  role       = aws_iam_role.app_task_execution.name
  policy_arn = aws_iam_policy.app_task_execution_ecr_pull.arn
}

resource "aws_iam_policy" "app_task_execution_cloudwatch_logs" {
  name        = "${local.project_name}-${substr(sha512("app-task-execution-cloudwatch-logs"), 0, 6)}"
  description = "${local.project_name}-app-task-execution-cloudwatch-logs"
  policy      = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "app_task_execution_cloudwatch_logs" {
  role       = aws_iam_role.app_task_execution.name
  policy_arn = aws_iam_policy.app_task_execution_cloudwatch_logs.arn
}

resource "aws_iam_role" "app_task" {
  name        = "${local.project_name}-${substr(sha512("app-task"), 0, 6)}"
  description = "${local.project_name}-app-task"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "app_task_s3_read" {
  name        = "${local.project_name}-${substr(sha512("app-task-s3-read"), 0, 6)}"
  description = "${local.project_name}-app-task-s3-read"
  policy = templatefile("${path.root}/policies/s3-object-read.json.tpl", {
    bucket_arn = aws_s3_bucket.models_store.arn
  })
}

resource "aws_iam_role_policy_attachment" "app_task_s3_read" {
  role       = aws_iam_role.app_task.name
  policy_arn = aws_iam_policy.app_task_s3_read.arn
}

resource "aws_iam_policy" "app_task_ssm_create_channels" {
  name        = "${local.project_name}-${substr(sha512("app-task-ssm-create-channels"), 0, 6)}"
  description = "${local.project_name}-app-task-ssm-create-channels"
  policy      = templatefile("${path.root}/policies/ssm-create-channels.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "app_task_ssm_create_channels" {
  role       = aws_iam_role.app_task.name
  policy_arn = aws_iam_policy.app_task_ssm_create_channels.arn
}
