resource "aws_ecs_cluster" "sejal_cluster" {
  name = "sejal-fargate-cluster"
}

resource "aws_ecs_task_definition" "sejal_task" {
  family                   = "sejal-fargate-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = "arn:aws:iam::811738710312:role/ecs_fargate_taskRole"
  task_role_arn      = "arn:aws:iam::811738710312:role/ecs_fargate_taskRole"

  container_definitions = jsonencode([
    {
      name      = "sejal-container"
      image     = var.image_url
      essential = true

      portMappings = [{
        containerPort = 1337
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.strapi_logs.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        {
          name  = "DATABASE_HOST"
          value = aws_db_instance.sejal_db.address
        },
        {
          name  = "DATABASE_USERNAME"
          value = var.db_username
        },
        {
          name  = "DATABASE_PASSWORD"
          value = var.db_password
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "sejal_service" {
  name            = "sejal-service"
  cluster         = aws_ecs_cluster.sejal_cluster.id
  task_definition = aws_ecs_task_definition.sejal_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}
