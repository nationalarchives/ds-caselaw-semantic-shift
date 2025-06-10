resource "aws_ecs_service" "app" {
  name            = "${local.project_name}-app-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [
      aws_subnet.app_public_a.id,
      aws_subnet.app_public_b.id,
    ]
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = true
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs_service_green.arn
    container_name   = "app"
    container_port   = 80
  }

  health_check_grace_period_seconds = 60

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  lifecycle {
    ignore_changes = [
      load_balancer,
      task_definition,
    ]
  }
}
