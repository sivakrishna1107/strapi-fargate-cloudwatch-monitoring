provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Random suffix for unique names
resource "random_id" "suffix" {
  byte_length = 4
}

# IAM Role for ECS Task Execution (ECR pull + CloudWatch logs)
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-${random_id.suffix.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Cluster
resource "aws_ecs_cluster" "strapi" {
  name = "strapi-cluster-${random_id.suffix.hex}"
  setting {
    name  = "containerInsights"
    value = "enabled"  # Enables CPU/Memory metrics
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/strapi"
  retention_in_days = 7
}

# Strapi Task Definition
resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task-${random_id.suffix.hex}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"  # Strapi needs more resources
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name  = "strapi"
    image = "${var.ecr_repo_url}:latest"  # Your Strapi ECR image
    portMappings = [{
      containerPort = 1337  # Strapi default port
      protocol      = "tcp"
    }]
    environment = [
      { name = "DATABASE_URL", value = var.database_url },  # Set in GitHub secrets
      { name = "JWT_SECRET", value = var.jwt_secret }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.strapi.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs/strapi"
      }
    }
  }])
}

# Security Group for ECS Tasks (ALB → port 1337)
resource "aws_security_group" "ecs_tasks" {
  vpc_id = data.aws_vpc.default.id
  ingress {
    from_port       = 1337
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB Security Group (HTTP 80/443)
resource "aws_security_group" "alb" {
  vpc_id = data.aws_vpc.default.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "aws_lb" "strapi" {
  name               = "strapi-alb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids
}

resource "aws_lb_target_group" "strapi" {
  name        = "strapi-tg-${random_id.suffix.hex}"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path     = "/admin"  # Strapi admin health check
    port     = "traffic-port"
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.strapi.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.strapi.arn
    type             = "forward"
  }
}

# ECS Service
resource "aws_ecs_service" "strapi" {
  name            = "strapi-service-${random_id.suffix.hex}"
  cluster         = aws_ecs_cluster.strapi.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 2  # HA across AZs

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.ecs_tasks.id]
  }
}

# Outputs
output "alb_dns" {
  value = aws_lb.strapi.dns_name
}

output "log_group" {
  value = aws_cloudwatch_log_group.strapi.name
}
