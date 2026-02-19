resource "aws_ecs_cluster" "sejal_cluster_siva" {
  name = "sejal-fargate-cluster-siva"
}

resource "aws_ecs_task_definition" "sejal_task_siva" {
  family                   = "sejal-fargate-task-siva"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "sejal-container-siva"
      image     = var.image_url
      essential = true

      portMappings = [{
        containerPort = 1337
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.strapi_logs_siva.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        { name = "DATABASE_HOST", value = aws_db_instance.sejal_db_siva.address },
        { name = "DATABASE_USERNAME", value = var.db_username },
        { name = "DATABASE_PASSWORD", value = var.db_password },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "NODE_ENV", value = "production" },
        { name = "HOST", value = "0.0.0.0" },
        { name = "PORT", value = "1337" }
      ]
    }
  ])
}

resource "aws_ecs_service" "sejal_service_siva" {
  name            = "sejal-service-siva"
  cluster         = aws_ecs_cluster.sejal_cluster_siva.id
  task_definition = aws_ecs_task_definition.sejal_task_siva.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg_siva.id]
    assign_public_ip = true
  }
}

