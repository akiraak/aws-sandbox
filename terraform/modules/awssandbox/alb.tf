# ================================================
# ALB
# ================================================
resource "aws_lb" "this" {
  name = "${var.name}-integrated-alb"

  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.web.id,
    aws_security_group.vpc.id,
  ]

  subnets = [
    aws_subnet.public_alb_1.id,
    aws_subnet.public_alb_2.id,
  ]

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = data.aws_acm_certificate.host_domain_wc_acm.arn
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "503 Service Temporarily Unavailable"
      status_code = "503"
    }
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ================================================
# Route53 record for ALB
# ================================================
resource "aws_route53_record" "a_record_for_api_subdomain" {
  name    = aws_route53_zone.api_subdomain.name
  type    = "A"
  zone_id = aws_route53_zone.api_subdomain.zone_id
  alias {
    evaluate_target_health = true
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
  }
}

# ================================================
# ALB maintenance HTML
# ================================================
locals {
  maintenance_body = <<EOF
  <!doctype html> <title>メンテナンス中</title> <style> body { text-align: center; padding: 150px; } h1 { font-size: 50px; } body { font: 20px Helvetica, sans-serif; color: #333; } article { display: block; text-align: left; width: 650px; margin: 0 auto; } a { color: #dc8100; text-decoration: none; } a:hover { color: #333; text-decoration: none; } </style> <article> <h1>只今メンテナンス中です</h1> <div> <p>システムの改修を行なっております。ご不便をおかけいたしますが今しばらくお待ちください。</p> <p>&mdash; 開発チーム</p> </div> </article>
EOF
}