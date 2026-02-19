resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/sejal-strapi"
  retention_in_days = 7
}

