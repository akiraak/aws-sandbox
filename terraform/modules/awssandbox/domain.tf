# ================================================
# Host zone
# ================================================
data aws_route53_zone host_domain {
  name = var.route53_zone_name
}

# ================================================
# api subdomain
# ================================================
resource aws_route53_zone api_subdomain {
  name = var.api_subdomain
}

resource aws_route53_record ns_record_for_api_subdomain {
  name    = aws_route53_zone.api_subdomain.name
  type    = "NS"
  zone_id = data.aws_route53_zone.host_domain.id
  records = [
    aws_route53_zone.api_subdomain.name_servers[0],
    aws_route53_zone.api_subdomain.name_servers[1],
    aws_route53_zone.api_subdomain.name_servers[2],
    aws_route53_zone.api_subdomain.name_servers[3],
  ]
  ttl = 172800
}

# ================================================
# Import Host domain Wildcard ACM
# ================================================
data aws_acm_certificate host_domain_wc_acm {
  domain = "*.${var.route53_zone_name}"
}

# ================================================
# Route53
# ================================================
/*
data "aws_route53_zone" "app" {
  name = "${var.route53_zone_app_name}"
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.app.zone_id
  name    = "api"
  type    = "A"
  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
*/
/*
resource "aws_route53_record" "admin" {
  zone_id = data.aws_route53_zone.app.zone_id
  name    = "admin"
  type    = "A"
  alias {
    name                   = aws_lb.admin.dns_name
    zone_id                = aws_lb.admin.zone_id
    evaluate_target_health = true
  }
}
*/