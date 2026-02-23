terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

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

resource "random_id" "suffix" {
  byte_length = 4
}

# Simplified for your perms - no IAM role creation
resource "aws_ecs_cluster" "strapi" {
  name = "strapi-${random_id.suffix.hex}"
}

resource "aws_cloudwatch_log_group" "strapi" {
  name = "/ecs/strapi"
}

resource "aws_ecs_task_definition" "strapi" {
  family = "strapi-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "512"
  memory = "1024"
  # Uses account default execution role
  
  container_definitions = jsonencode([{
    name  = "strapi"
    image = var.ecr_repo_url
    portMappings = [{ containerPort = 1337 }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.strapi.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs/strapi"
      }
    }
  }])
}

resource "aws_lb" "strapi" {
  name               = "strapi-alb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnets.public.ids
}

resource "aws_lb_target_group" "strapi" {
  name     = "strapi-tg-${random_id.suffix.hex}"
  port     = 1337
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.strapi.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi.arn
  }
}

resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  network_configuration {
    subnets = data.aws_subnets.public.ids
  }
}

output "alb_url" {
  value = "http://${aws_lb.strapi.dns_name}"
}
