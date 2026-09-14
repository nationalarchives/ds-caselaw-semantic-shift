resource "aws_cloudwatch_log_group" "beta" {
  name              = "/ecs/beta"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "beta" {
  family = "${local.project_name}-beta"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name        = local.beta_container_name
      image                 = module.beta_ecr.repository_url
      entrypoint            = jsonencode(local.beta_entrypoint)
      environment           = jsonencode(local.beta_environment),
      host_port             = local.beta_container_port
      container_port        = local.beta_container_port
      linux_parameters      = jsonencode(local.beta_linux_parameters)
      cloudwatch_log_group  = aws_cloudwatch_log_group.beta.name
      awslogs_stream_prefix = local.beta_awslogs_stream_prefix
      region                = local.aws_region
    }
  )
  execution_role_arn       = module.beta_task_execution_role.role_arn
  task_role_arn            = module.beta_task_role.role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = local.beta_task_memory
  cpu                      = local.beta_task_cpu
}
