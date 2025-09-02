resource "aws_security_group" "ecs_service_alb" {
  name        = "${local.project_name}-ecs-service-alb"
  description = "ECS service ALB"
  vpc_id      = aws_vpc.app.id
}

resource "aws_security_group_rule" "ecs_service_alb_container_egress_tcp" {
  description              = "Allow container port tcp egress to containers"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.ecs_service_alb.id
}

resource "aws_security_group_rule" "ecs_service_alb_http_ingress" {
  description       = "Allow port 80 (http) ingress for the service ALB"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service_alb.id
}

resource "aws_security_group_rule" "ecs_service_alb_https_ingress" {
  description       = "Allow port 443 (https) ingress for the service ALB"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service_alb.id
}

resource "aws_alb" "ecs_service" {
  name = "${local.project_name}-ecs-service"

  load_balancer_type         = "application"
  internal                   = false
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"
  preserve_host_header       = true
  xff_header_processing_mode = "append"

  subnets = [
    aws_subnet.app_public_a.id,
    aws_subnet.app_public_b.id
  ]

  security_groups = [
    aws_security_group.ecs_service_alb.id,
  ]

  idle_timeout = 60

  tags = {
    Name = "${local.project_name}-ecs-service"
  }
}

resource "aws_alb_target_group" "ecs_service_blue" {
  name = "${local.project_name}-ecs-service-b"

  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app.id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 60
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200,301,302"
  }

  deregistration_delay = 60
}

resource "aws_alb_target_group" "ecs_service_green" {
  name = "${local.project_name}-ecs-service-g"

  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app.id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 60
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200,301,302"
  }

  deregistration_delay = 60
}

resource "aws_alb_listener" "ecs_service_http_https_redirect" {
  load_balancer_arn = aws_alb.ecs_service.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "ecs_service_http_https" {
  load_balancer_arn = aws_alb.ecs_service.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = local.app_alb_tls_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Misdirected Request"
      status_code  = "421"
    }
  }
}

resource "aws_alb_listener_rule" "ecs_service_http_host_header" {
  listener_arn = aws_alb_listener.ecs_service_http_https.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_service_blue.arn
  }

  condition {
    host_header {
      values = local.app_cloudfront_aliases
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
  }
}
