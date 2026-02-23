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
  filter {
    name   = "tag:Name"
    values = ["*public*", "*Public*"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "my-fargate-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS Task Definition - NO LOGS, PUBLIC IMAGE ONLY
resource "aws_ecs_task_definition" "app" {
  family                   = "my-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  # NO execution_role_arn - Fargate uses account default
  # NO awslogs - avoids role requirement

  container_definitions = jsonencode([
    {
      name  = "my-app"
      image = "amazon/amazon-ecs-sample"  # ✅ Public image, no ECR/pull needed
      essential = true
      portMappings = [{
        containerPort = 80
        protocol      = "tcp"
      }]
      # NO logConfiguration - uses ECS platform logs
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.public.ids
    assign_public_ip = true
  }

  desired_count = 1
}
