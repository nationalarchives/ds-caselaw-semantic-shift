resource "aws_alb_target_group" "beta_blue" {
  name = "${local.project_name}-beta-b"

  port        = local.beta_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app.id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 60
    path                = local.beta_alb_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-399"
  }

  deregistration_delay = 60
}

resource "aws_alb_target_group" "beta_green" {
  name = "${local.project_name}-beta-g"

  port        = local.beta_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app.id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 60
    path                = local.beta_alb_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-399"
  }

  deregistration_delay = 60
}

# Evaluated before the alpha host-only rule (see ecs-service-alb.tf) so /beta
# traffic is routed to Beta even though the alpha rule has no path condition.
resource "aws_alb_listener_rule" "beta_service_path" {
  listener_arn = aws_alb_listener.ecs_service_http_https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.beta_blue.arn
  }

  condition {
    host_header {
      values = local.app_cloudfront_aliases
    }
  }

  condition {
    path_pattern {
      values = [local.beta_cloudfront_path_pattern]
    }
  }

  condition {
    http_header {
      http_header_name = "X-CloudFront-Secret"
      values           = [random_password.app_service_cloudfront_bypass_protection_secret.result]
    }
  }

  lifecycle {
    ignore_changes = [
      action,
    ]

    replace_triggered_by = [
      aws_alb_target_group.beta_blue,
    ]
  }
}
