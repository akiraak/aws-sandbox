/*
# ================================================
# S3: challenge cover image
# ================================================
data "aws_iam_policy_document" "challenge_cover_image" {
  statement {
    sid = "PublicReadGetObject"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.name}-challenge-cover-image/*",
    ]
  }
}

resource "aws_s3_bucket" "challenge_cover_image" {
  bucket = "${var.name}-challenge-cover-image"
}

resource "aws_s3_bucket_policy" "challenge_cover_image" {
  bucket = aws_s3_bucket.challenge_cover_image.id
  policy = data.aws_iam_policy_document.challenge_cover_image.json
}

# ================================================
# S3: uesr challenge image
# ================================================
data "aws_iam_policy_document" "user_challenge_image" {
  statement {
    sid = "PublicReadGetObject"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.name}-user-challenge-image/*",
    ]
  }
}

resource "aws_s3_bucket" "user_challenge_image" {
  bucket = "${var.name}-user-challenge-image"
}

resource "aws_s3_bucket_policy" "user_challenge_image" {
  bucket = aws_s3_bucket.user_challenge_image.id
  policy = data.aws_iam_policy_document.user_challenge_image.json
}

# ================================================
# S3: official post image
# ================================================
data "aws_iam_policy_document" "official_post_image" {
  statement {
    sid = "PublicReadGetObject"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.name}-official-post-image/*",
    ]
  }
}

resource "aws_s3_bucket" "official_post_image" {
  bucket = "${var.name}-official-post-image"
}

resource "aws_s3_bucket_policy" "official_post_image" {
  bucket = aws_s3_bucket.official_post_image.id
  policy = data.aws_iam_policy_document.official_post_image.json
}

# ================================================
# S3: event image
# ================================================
data "aws_iam_policy_document" "event_image" {
  statement {
    sid = "PublicReadGetObject"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.name}-event-image/*",
    ]
  }
}

resource "aws_s3_bucket" "event_image" {
  bucket = "${var.name}-event-image"
}

resource "aws_s3_bucket_policy" "event_image" {
  bucket = aws_s3_bucket.event_image.id
  policy = data.aws_iam_policy_document.event_image.json
}
*/

# ================================================
# S3 endpoint
# ================================================
/*
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id        = aws_vpc.main.id
  service_name  = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  tags = {
      Name = "${var.name}-s3"
  }
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
  route_table_id  = aws_route_table.private.id
}
*/