resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/app"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "app" {
  family = "${local.project_name}-app"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name = "app"
      image          = aws_ecr_repository.app.repository_url
      entrypoint     = jsonencode(local.app_entrypoint)
      environment    = jsonencode([]),
      host_port      = 80
      container_port = 80
      linux_parameters = jsonencode({
        initProcessEnabled = false
      })
      cloudwatch_log_group  = aws_cloudwatch_log_group.app.name
      awslogs_stream_prefix = "app"
      region                = local.aws_region
    }
  )
  execution_role_arn       = aws_iam_role.app_task_execution.arn
  task_role_arn            = aws_iam_role.app_task.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = 2048
  cpu                      = 1024

  depends_on = [
    aws_iam_role_policy_attachment.app_task_execution_ecr_pull,
    aws_iam_role_policy_attachment.app_task_execution_cloudwatch_logs,
  ]
}
