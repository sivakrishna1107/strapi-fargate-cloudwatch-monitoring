resource "aws_ecs_cluster" "cluster_siva" {
  name = "fargate-cluster-siva"
}

resource "aws_ecs_task_definition" "task_siva" {
  family                   = "fargate-task-siva"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "container-siva"
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
        { name = "DATABASE_HOST", value = aws_db_instance.db_siva.address },
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

resource "aws_ecs_service" "service_siva" {
  name            = "service-siva"
  cluster         = aws_ecs_cluster.cluster_siva.id
  task_definition = aws_ecs_task_definition.task_siva.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg_siva.id]
    assign_public_ip = true
  }
}

