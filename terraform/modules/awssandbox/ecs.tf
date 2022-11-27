# ================================================
# ECS Cluster
# ================================================
resource "aws_ecs_cluster" "app" {
  name               = "${var.name}-app"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_ecs_cluster_capacity_providers" "app" {
  cluster_name = aws_ecs_cluster.app.name
  capacity_providers = ["FARGATE"]
  
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ================================================
# ECS IAM Role
# ================================================
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.name}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}
resource "aws_iam_role_policy" "kms_decrypt_policy" {
  name = "${var.name}_ecs_task_execution_role_policy_kms"
  role               = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt"
        ],
        "Resource": [
          "*"
        ]
      }
    ]
  })
}

# ================================================
# CloudWatch Log Group: APP
# ================================================
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name}/app"
  retention_in_days = 30
}

# ================================================
# ECS Task Definition: APP
# ================================================
data "aws_caller_identity" "current" {}

locals {
  app_task_container_name = "${var.name}-app-container"
}
data "aws_ssm_parameter" "ENV_TYPE" {
  name = "${var.ssm_parameter_store_base}/ENV_TYPE"
}
data "aws_ssm_parameter" "SQLALCHEMY_DATABASE_URI" {
  name = "${var.ssm_parameter_store_base}/SQLALCHEMY_DATABASE_URI"
}
data "aws_ssm_parameter" "SQLALCHEMY_CHECK_SAME_THREAD" {
  name = "${var.ssm_parameter_store_base}/SQLALCHEMY_CHECK_SAME_THREAD"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    {
      name             = local.app_task_container_name
      image            = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.name}-api:latest"
      portMappings     = [{ containerPort : 80 }]
      secrets = [
        {
          name: "ENV_TYPE"
          valueFrom: data.aws_ssm_parameter.ENV_TYPE.arn
        },
        {
          name: "SQLALCHEMY_DATABASE_URI"
          valueFrom: data.aws_ssm_parameter.SQLALCHEMY_DATABASE_URI.arn
        },
        {
          name: "SQLALCHEMY_CHECK_SAME_THREAD"
          valueFrom: data.aws_ssm_parameter.SQLALCHEMY_CHECK_SAME_THREAD.arn
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-region : var.region
          awslogs-group : aws_cloudwatch_log_group.app.name
          awslogs-stream-prefix : "ecs"
        }
      }
    }
  ])
}

# ================================================
# ECS Task Service: APP
# ================================================
resource "aws_ecs_service" "app" {
  name                               = "${var.name}-app"
  cluster                            = aws_ecs_cluster.app.id
  platform_version                   = "LATEST"
  task_definition                    = aws_ecs_task_definition.app.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  propagate_tags                     = "SERVICE"
  enable_execute_command             = true
  launch_type                        = "FARGATE"
  health_check_grace_period_seconds  = 60
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  network_configuration {
    assign_public_ip = false
    subnets          = [
      for s in aws_subnet.private_app : s.id
    ]
    security_groups = [
      aws_security_group.vpc.id,
      aws_security_group.db.id,
    ]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_app.arn
    container_name   = local.app_task_container_name
    container_port   = 80
  }
}

# ================================================
# ALB Target Group: APP
# ================================================
resource "aws_lb_target_group" "ecs_app" {
  name                 = "${var.name}-ecs-app"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 60
  health_check { path = "/docs" }
}

resource "aws_lb_listener_rule" "ecs_app_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_app.arn
  }
  condition {
    host_header {
      values = [var.api_subdomain]
    }
  }
}

resource "aws_lb_listener_rule" "ecs_app_maintenance" {
  listener_arn = aws_lb_listener.https.arn
  priority = 100
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = local.maintenance_body
      status_code = "503"
    }
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}