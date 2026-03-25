# Shared ALB data sources
data "aws_lb" "shared" {
  count = local.create_alb ? 0 : 1
  name  = local.shared_alb_name
}

data "aws_lb_listener" "shared_http" {
  count             = local.create_alb ? 0 : 1
  load_balancer_arn = data.aws_lb.shared[0].arn
  port              = 80
}

data "aws_lb_listener" "shared_https" {
  count             = !local.create_alb && var.aws_lb_enable_https ? 1 : 0
  load_balancer_arn = data.aws_lb.shared[0].arn
  port              = 443
}

locals {
  alb_dns_name       = local.create_alb ? aws_alb.default[0].dns_name : data.aws_lb.shared[0].dns_name
  alb_zone_id        = local.create_alb ? aws_alb.default[0].zone_id : data.aws_lb.shared[0].zone_id
  http_listener_arn  = local.create_alb ? aws_alb_listener.http[0].arn : data.aws_lb_listener.shared_http[0].arn
  https_listener_arn = var.aws_lb_enable_https ? (local.create_alb ? aws_alb_listener.https[0].arn : data.aws_lb_listener.shared_https[0].arn) : ""
}

# Shared Load Balancer
resource "aws_alb" "default" {
  count = local.create_alb ? 1 : 0
  name  = local.shared_alb_name

  security_groups    = [aws_security_group.load_balancer[0].id]
  load_balancer_type = "application"
  internal           = var.aws_lb_is_internal

  subnets = var.aws_lb_subnet_ids

  # lifecycle {
  #   prevent_destroy = true
  # }
}

moved {
  from = aws_alb.default
  to   = aws_alb.default[0]
}

resource "aws_alb_listener" "http" {
  count             = local.create_alb ? 1 : 0
  load_balancer_arn = aws_alb.default[0].arn

  port     = 80
  protocol = "HTTP"

  dynamic "default_action" {
    for_each = var.aws_lb_enable_https ? [1] : []

    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.aws_lb_enable_https ? [] : [1]

    content {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  }
}

moved {
  from = aws_alb_listener.http
  to   = aws_alb_listener.http[0]
}

resource "aws_alb_listener" "https" {
  count             = local.create_alb && var.aws_lb_enable_https ? 1 : 0
  load_balancer_arn = aws_alb.default[0].arn

  port       = 443
  protocol   = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"

  certificate_arn = data.aws_acm_certificate.wildcard[0].arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# Listener rules (host-based routing)
resource "aws_lb_listener_rule" "http" {
  count        = !var.aws_lb_enable_https ? 1 : 0
  listener_arn = local.http_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.default.arn
  }

  condition {
    host_header {
      values = [local.fqdns_domain]
    }
  }
}

resource "aws_lb_listener_rule" "https" {
  count        = var.aws_lb_enable_https ? 1 : 0
  listener_arn = local.https_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.default.arn
  }

  condition {
    host_header {
      values = [local.fqdns_domain]
    }
  }
}

/**
 * Blue deployment configuration.
 */
resource "aws_alb_target_group" "default" {
  name     = local.cannonical_name
  port     = var.aws_instance_web_port
  protocol = var.aws_instance_web_protocol
  vpc_id   = var.aws_vpc_id

  deregistration_delay = var.aws_lb_deregistration_delay

  stickiness {
    type            = "lb_cookie"
    cookie_duration = var.aws_lb_cookie_duration
    enabled         = var.aws_lb_enable_stickiness
  }

  health_check {
    path              = var.aws_lb_health_check_url
    interval          = 5
    timeout           = 4
    healthy_threshold = 3
  }
}

resource "aws_autoscaling_group" "default" {
  name                = local.cannonical_name
  vpc_zone_identifier = var.aws_instances_subnet_ids

  desired_capacity = var.aws_asg_instances_desired
  max_size         = var.aws_asg_instances_max
  min_size         = var.aws_asg_instances_min

  health_check_type         = var.aws_lb_health_check_type
  health_check_grace_period = var.aws_lb_health_check_grace_period
  target_group_arns         = [aws_alb_target_group.default.arn]

  launch_template {
    id      = aws_launch_template.default.id
    version = aws_launch_template.default.latest_version
  }
}
