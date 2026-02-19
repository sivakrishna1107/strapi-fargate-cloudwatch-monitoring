resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "strapi",
      image = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/strapi:latest",
      essential = true,

      portMappings = [{
        containerPort = 1337,
        hostPort      = 1337
      }],

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.strapi.name,
          awslogs-region        = "ap-south-1",
          awslogs-stream-prefix = "ecs/strapi"
        }
      }
    }
  ])
}

