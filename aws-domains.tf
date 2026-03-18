/**
 * Domain related configurations, like DNS and Certificates.
 */

data "aws_route53_zone" "domain" {
  name         = "${var.aws_hosted_domain}."
  private_zone = var.aws_lb_is_internal
}

data "aws_acm_certificate" "wildcard" {
  count    = local.create_alb && !var.aws_lb_is_internal ? 1 : 0
  domain   = "*.${var.aws_hosted_domain}"
  statuses = ["ISSUED"]
}

resource "aws_route53_record" "default" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = local.fqdns_domain
  type    = "A"

  alias {
    name                   = local.alb_dns_name
    zone_id                = local.alb_zone_id
    evaluate_target_health = true
  }
}