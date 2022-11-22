# ================================================
# IAM Role: App Runner
# ================================================

#data "aws_caller_identity" "current" {}

# ================================================
# App Runner: api
# ================================================
/*
resource "aws_apprunner_service" "api" {
  service_name = "${var.name}-api"

  source_configuration {
    authentication_configuration {
      #access_role_arn = aws_iam_role.apprunner.arn
      access_role_arn = "arn:aws:iam::298862159565:role/service-role/AppRunnerECRAccessRole"
    }
    image_repository {
      image_configuration {
        port = "8000"
      }
      #image_identifier      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.name}-api:latest"
      image_identifier      = "298862159565.dkr.ecr.ap-northeast-1.amazonaws.com/cabostg-api:latest"
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = false
  }

  tags = {
    Name = "${var.name}-api"
  }
}
*/
/*
# ================================================
# App Runner: admin
# ================================================
resource "aws_apprunner_service" "admin" {
  service_name = "${var.name}-admin"

  source_configuration {
    image_repository {
      image_configuration {
        port = "8000"
      }
      image_identifier      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.name}-admin:latest"
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = var.auto_deploy
  }

  tags = {
    Name = "${var.name}-admin"
  }
}*/
