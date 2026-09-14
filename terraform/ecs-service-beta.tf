resource "aws_ecs_service" "beta" {
  name            = "${local.project_name}-beta-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.beta.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [
      aws_subnet.app_public_a.id,
      aws_subnet.app_public_b.id,
    ]
    security_groups  = [module.beta_security_group.security_group_id]
    assign_public_ip = true
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.beta_blue.arn
    container_name   = local.beta_container_name
    container_port   = local.beta_container_port
  }

  health_check_grace_period_seconds = 120

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  lifecycle {
    ignore_changes = [
      load_balancer,
      task_definition,
    ]
  }
}
