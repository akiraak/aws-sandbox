# ================================================
# Subnet: Public app alb
# ================================================
resource "aws_subnet" "public_app_alb_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.subnet_public_app_alb_1_cidr_block
  availability_zone = var.az_1
  tags = {
    Name = "${var.name}-public-app-alb-1"
  }
}

resource "aws_subnet" "public_app_alb_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.subnet_public_app_alb_2_cidr_block
  availability_zone = var.az_2
  tags = {
    Name = "${var.name}-public-app-alb-2"
  }
}

resource "aws_route_table_association" "public_app_alb_1" {
  subnet_id      = aws_subnet.public_app_alb_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_app_alb_2" {
  subnet_id      = aws_subnet.public_app_alb_2.id
  route_table_id = aws_route_table.public.id
}

# ================================================
# Security group: app alb
# ================================================
resource "aws_security_group" "app_alb" {
  name                   = "${var.name}-app-alb"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = false

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-app-alb"
  }
}

# http
resource "aws_security_group_rule" "alb_permit_from_internet_http" {
  security_group_id = aws_security_group.app_alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "permit from internet for http."
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
}

# https
resource "aws_security_group_rule" "alb_permit_from_internet_https" {
  security_group_id = aws_security_group.app_alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "permit from internet for https."
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
}

/*
# ALBアカウントIDを取得するために使用
data "aws_elb_service_account" "main" {}

# ================================================
# ログ格納用バケットポリシー
# ================================================
data "aws_iam_policy_document" "logging_bucket" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = [
        data.aws_elb_service_account.main.arn
      ]
      type        = "AWS"
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${var.name}-logging",
      "arn:aws:s3:::${var.name}-logging/*"
    ]
  }
}

# ================================================
# ログ格納用バケット
# ================================================
resource "aws_s3_bucket" "logging" {
  bucket = "${var.name}-logging"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.logging.id
  policy = data.aws_iam_policy_document.logging_bucket.json
}

resource "aws_s3_bucket_lifecycle_configuration" "logging" {
  bucket = aws_s3_bucket.logging.id
  rule {
    id      = "assets"
    expiration {
      days = "365"
    }
    status = "Enabled"
   }
}

# S3 Public Access Block
## パブリックアクセスはしないため全て有効にする。
resource "aws_s3_bucket_public_access_block" "logging" {
  bucket                  = aws_s3_bucket.logging.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ================================================
# ALB Target group: app
# ================================================
resource "aws_lb_target_group" "app" {
  name        = "${var.name}-tg-app"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  # 登録解除を実行するまでの待機時間。
  deregistration_delay = 300 # 処理中のリクエストの完了するのを待つためにデフォルト値を採用。

  # 登録された後にリクエストを開始する猶予時間
  slow_start = 0 # 登録されたらすぐに開始してよいので無効。

  load_balancing_algorithm_type = "round_robin" # ラウンドロビンで平均的にリクエストを分散。

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400 # 要件が決まっていないのでとりあえず1日を設定。
    enabled         = true
  }

  health_check {
    enabled             = true
    interval            = 30
    path                = "/docs"
    port                = "traffic-port" # トラフィックを受信するポートを使用。デフォルト。
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-299"
  }
}

# ================================================
# ALB Listener: app
# ================================================
# https
resource "aws_lb_listener" "app_https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn_app
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Listener: HTTPをHTTPSにリダイレクトするためのリスナー
resource "aws_lb_listener" "app_http_redirect_to_https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ================================================
# ALB: app
# ================================================
resource "aws_lb" "app" {
  name               = "${var.name}-app"
  internal           = false # 内部で使用しないため無効。
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.app_alb.id
  ]

  access_logs {
    bucket  = aws_s3_bucket.logging.bucket
    prefix  = "elb"
    enabled = true
  }

  subnets = [
    aws_subnet.public_app_alb_1.id,
    aws_subnet.public_app_alb_2.id
  ]

  idle_timeout               = 60    # デフォルトの60秒を設定。
  enable_deletion_protection = false # Terraformで削除したいため無効。
  enable_http2               = true
  ip_address_type            = "ipv4" # ipv6は使用しないためipv4を指定。
}
*/

/*
# ================================================
# ALB Target group: admin
# ================================================
resource "aws_lb_target_group" "admin" {
  name        = "${var.name}-tg-admin"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  # 登録解除を実行するまでの待機時間。
  deregistration_delay = 300 # 処理中のリクエストの完了するのを待つためにデフォルト値を採用。

  # 登録された後にリクエストを開始する猶予時間
  slow_start = 0 # 登録されたらすぐに開始してよいので無効。

  load_balancing_algorithm_type = "round_robin" # ラウンドロビンで平均的にリクエストを分散。

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400 # 要件が決まっていないのでとりあえず1日を設定。
    enabled         = true
  }

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port" # トラフィックを受信するポートを使用。デフォルト。
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-299"
  }
}

# ================================================
# ALB Listener: admin
# ================================================
# https
resource "aws_lb_listener" "admin_https" {
  load_balancer_arn = aws_lb.admin.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn_admin
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin.arn
  }
}

# Listener: HTTPをHTTPSにリダイレクトするためのリスナー
resource "aws_lb_listener" "admin_http_redirect_to_https" {
  load_balancer_arn = aws_lb.admin.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ================================================
# ALB: admin
# ================================================
resource "aws_lb" "admin" {
  name               = "${var.name}-admin"
  internal           = false # 内部で使用しないため無効。
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.app_alb.id
  ]

  access_logs {
    bucket  = aws_s3_bucket.logging.bucket
    prefix  = "elb"
    enabled = true
  }

  subnets = [
    aws_subnet.public_app_alb_1.id,
    aws_subnet.public_app_alb_2.id
  ]

  idle_timeout               = 60    # デフォルトの60秒を設定。
  enable_deletion_protection = false # Terraformで削除したいため無効。
  enable_http2               = true
  ip_address_type            = "ipv4" # ipv6は使用しないためipv4を指定。
}
*/

####################################################
# ALB Security Group
####################################################
resource "aws_security_group" "alb" {
  name = "${var.name}-integrated-alb"
  description = "${var.name} alb rule based routing"
  vpc_id = aws_vpc.main.id
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}-integrated-alb"
  }
}

resource "aws_security_group_rule" "alb_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 80
  type              = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_https" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "this" {
  name = "${var.name}-integrated-alb"
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.app_alb.id
  ]
  subnets = [
    aws_subnet.public_app_alb_1.id,
    aws_subnet.public_app_alb_2.id,
  ]
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

####################################################
# Route53 record for ALB
####################################################
/*
resource "aws_route53_record" "a_record_for_app_subdomain" {
  name    = aws_route53_zone.app_subdomain.name
  type    = "A"
  zone_id = aws_route53_zone.app_subdomain.zone_id
  alias {
    evaluate_target_health = true
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
  }
}
*/
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

####################################################
# ALB maintenance HTML
####################################################

locals {
  maintenance_body = <<EOF
  <!doctype html> <title>メンテナンス中</title> <style> body { text-align: center; padding: 150px; } h1 { font-size: 50px; } body { font: 20px Helvetica, sans-serif; color: #333; } article { display: block; text-align: left; width: 650px; margin: 0 auto; } a { color: #dc8100; text-decoration: none; } a:hover { color: #333; text-decoration: none; } </style> <article> <h1>只今メンテナンス中です</h1> <div> <p>システムの改修を行なっております。ご不便をおかけいたしますが今しばらくお待ちください。</p> <p>&mdash; 開発チーム</p> </div> </article>
EOF
}