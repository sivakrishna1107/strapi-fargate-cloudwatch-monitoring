resource "aws_cloudwatch_log_group" "strapi_logs_siva" {
  name              = "/ecs/strapi-siva"
  retention_in_days = 7
}

