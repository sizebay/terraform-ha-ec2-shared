/**
 * Domain related configurations, like DNS and Certificates.
 */

data "aws_route53_zone" "domain" {
  count        = var.create_dns_record ? 1 : 0
  name         = "${var.aws_hosted_domain}."
  private_zone = var.dns_private_zone
}

data "aws_acm_certificate" "wildcard" {
  count    = local.create_alb && var.aws_lb_enable_https ? 1 : 0
  domain   = "*.${var.aws_hosted_domain}"
  statuses = ["ISSUED"]
}

resource "aws_route53_record" "default" {
  count   = var.create_dns_record ? 1 : 0
  zone_id = data.aws_route53_zone.domain[0].zone_id
  name    = local.fqdns_domain
  type    = "A"

  alias {
    name                   = local.alb_dns_name
    zone_id                = local.alb_zone_id
    evaluate_target_health = true
  }
}
