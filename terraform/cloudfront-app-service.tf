resource "aws_cloudfront_function" "app_service_viewer_request" {
  name    = "app-service-viewer-request"
  runtime = "cloudfront-js-2.0"
  comment = "App service viewer request"
  publish = true
  code = templatefile("${path.root}/cloudfront-functions/viewer-request.js.tpl", {
    basic_auth_user_list = jsonencode(local.app_cloudfront_basic_auth_user_list)
  })
}

data "aws_cloudfront_cache_policy" "managed_policy" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "managed_policy" {
  name = "Managed-AllViewerAndCloudFrontHeaders-2022-06"
}

data "aws_cloudfront_response_headers_policy" "managed_policy" {
  name = "Managed-CORS-with-preflight-and-SecurityHeadersPolicy"
}

resource "aws_cloudfront_distribution" "app_service" {
  enabled         = true
  aliases         = local.app_cloudfront_aliases
  is_ipv6_enabled = true
  http_version    = "http2and3"
  price_class     = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn      = local.app_cloudfront_tls_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  origin {
    domain_name = aws_alb.ecs_service.dns_name
    origin_id   = "app-default"

    connection_attempts = 3
    connection_timeout  = 10

    custom_origin_config {
      origin_protocol_policy   = "https-only"
      http_port                = "80"
      https_port               = "443"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "app-default"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id            = data.aws_cloudfront_cache_policy.managed_policy.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.managed_policy.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.managed_policy.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.app_service_viewer_request.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
