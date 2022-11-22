####################################################
# ECS Cluster
####################################################

resource "aws_ecs_cluster" "this" {
  name               = "${var.name}-app-cluster"
  #capacity_providers = ["FARGATE"]
  /*
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }*/
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]
  
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

####################################################
# ECS IAM Role
####################################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
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
          #data.aws_ssm_parameter.database_password.arn
          "*"
        ]
      }
    ]
  })
}

####################################################
# ECS Task Container Log Groups
####################################################
/*
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.app_name}/frontend"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "backend_middleware" {
  name              = "/ecs/${local.app_name}/backend/middleware"
  retention_in_days = 30
}
*/
resource "aws_cloudwatch_log_group" "backend_app" {
  name              = "/ecs/${var.name}/backend/api"
  retention_in_days = 30
}

####################################################
# ECS Task Definition
####################################################

data "aws_caller_identity" "current" {}

locals {
  #frontend_task_name = "${local.app_name}-app-task-frontend"
  backend_task_name = "${var.name}-api-task-backend"
  #frontend_task_container_name = "${local.app_name}-app-container-next-frontend"
  #backend_task_middleware_container_name = "${local.app_name}-app-container-nginx-backend"
  backend_task_app_container_name = "${var.name}-api-container"
}
data "aws_ssm_parameter" "app_env" {
  name = "${var.ssm_parameter_store_base}/app_env"
}
data "aws_ssm_parameter" "SQLALCHEMY_DATABASE_URI" {
  name = "${var.ssm_parameter_store_base}/SQLALCHEMY_DATABASE_URI"
}
data "aws_ssm_parameter" "SQLALCHEMY_CHECK_SAME_THREAD" {
  name = "${var.ssm_parameter_store_base}/SQLALCHEMY_CHECK_SAME_THREAD"
}
/*
data "aws_ssm_parameter" "app_key" {
  name = "${local.ssm_parameter_store_base}/app_key"
}
*/

/*
resource "aws_ecs_task_definition" "frontend" {
  family                   = local.frontend_task_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    {
      name             = local.frontend_task_container_name
      image            = "${data.aws_ecr_repository.frontend.repository_url}:${local.ecr_frontend_repository_newest_tags[0]}"
      portMappings     = [{ containerPort : 3000 }]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-region : "ap-northeast-1"
          awslogs-group : aws_cloudwatch_log_group.frontend.name
          awslogs-stream-prefix : "ecs"
        }
      }
    }
  ])
}
*/

resource "aws_ecs_task_definition" "backend" {
  family                   = local.backend_task_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    /*
    {
      name             = local.backend_task_middleware_container_name
      image            = "${data.aws_ecr_repository.backend_middleware.repository_url}:${local.ecr_backend_middleware_repository_newest_tags[0]}"
      portMappings     = [{ containerPort : 80 }]
      volumesFrom = [{
        sourceContainer: local.backend_task_app_container_name
        readOnly: null
      }]
      dependsOn = [{
          containerName: local.backend_task_app_container_name
          condition: "START"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-region : "ap-northeast-1"
          awslogs-group : aws_cloudwatch_log_group.backend_middleware.name
          awslogs-stream-prefix : "ecs"
        }
      }
    },
    */
    {
      name             = local.backend_task_app_container_name
      #image            = "${data.aws_ecr_repository.backend_app.repository_url}:latest"
      image            = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.name}-api:latest"
      portMappings     = [{ containerPort : 80 }]
      secrets = [
        {
          name: "ENV_TYPE"
          valueFrom: data.aws_ssm_parameter.app_env.arn
        },
        /*
        {
          name: "APP_KEY"
          valueFrom: data.aws_ssm_parameter.app_key.arn
        },*/
        /*
        {
          name: "DB_DATABASE"
          valueFrom: data.aws_ssm_parameter.database_name.arn
        },
        {
          name: "DB_USERNAME"
          valueFrom: data.aws_ssm_parameter.database_user.arn
        },
        {
          name: "DB_PASSWORD"
          valueFrom: data.aws_ssm_parameter.database_password.arn
        },
        {
          name: "DB_HOST"
          valueFrom: aws_ssm_parameter.database_url.arn
        }*/
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
          awslogs-group : aws_cloudwatch_log_group.backend_app.name
          awslogs-stream-prefix : "ecs"
        }
      }
    }
  ])
}

####################################################
# ECS Cluster Service
####################################################

/*
resource "aws_ecs_service" "frontend" {
  name                               = "${local.app_name}-frontend"
  cluster                            = aws_ecs_cluster.this.id
  platform_version                   = "LATEST"
  task_definition                    = aws_ecs_task_definition.frontend.arn
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
    assign_public_ip = true
    subnets          = [
      aws_subnet.public_1a.id,
    ]
    security_groups = [
      aws_security_group.app.id,
    ]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = local.frontend_task_container_name
    container_port   = 3000
  }
}

resource "aws_lb_target_group" "frontend" {
  name                 = "${local.app_name}-service-tg-frontend"
  vpc_id               = aws_vpc.this.id
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 60
  health_check { path = "/api/healthcheck" }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
  condition {
    host_header {
      values = [local.app_domain_name]
    }
  }
}
*/

resource "aws_ecs_service" "backend" {
  name                               = "${var.name}-backend"
  cluster                            = aws_ecs_cluster.this.id
  platform_version                   = "LATEST"
  task_definition                    = aws_ecs_task_definition.backend.arn
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
    assign_public_ip = true
    subnets          = [
      #aws_subnet.public_1c.id,
      aws_subnet.public_app_alb_1.id,
    ]
    security_groups = [
      #aws_security_group.app.id,
      aws_security_group.app_alb.id
    ]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    #container_name   = local.backend_task_middleware_container_name
    container_name   = local.backend_task_app_container_name
    container_port   = 80
  }
}

resource "aws_lb_target_group" "backend" {
  name                 = "${var.name}-service-tg-backend"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 60
  health_check { path = "/docs" }
}

resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    host_header {
      #values = [local.api_domain_name]
      values = [var.api_subdomain]
    }
  }
}

resource "aws_lb_listener_rule" "maintenance" {
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