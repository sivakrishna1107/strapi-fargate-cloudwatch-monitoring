# Provider configuration
provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# Data source for default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source for default subnets (public subnets in default VPC)
data "aws_subnets" "default_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*public*","*Public*"]
  }
}

# Data source for default ECS task execution role (ecsTaskExecutionRole)
data "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "my-fargate-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS Task Definition using ECR image
resource "aws_ecs_task_definition" "app" {
  family                   = "my-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "my-app"
      image = "<your-account-id>.dkr.ecr.us-east-1.amazonaws.com/your-repo:latest"  # Replace with your ECR image URI
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/my-app"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# CloudWatch Log Group for the task
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/my-app"
  retention_in_days = 7
}

# ECS Service with Fargate
resource "aws_ecs_service" "main" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default_public.ids
    assign_public_ip = true  # Enable for default VPC public subnets to get public IP
  }

  desired_count = 1

  depends_on = [aws_cloudwatch_log_group.ecs_logs]
}
