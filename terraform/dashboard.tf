resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "strapi-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "strapi-cluster", "ServiceName", "strapi-service"],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "strapi-cluster", "ServiceName", "strapi-service"],
            ["AWS/ECS", "RunningTaskCount", "ClusterName", "strapi-cluster", "ServiceName", "strapi-service"],
            ["AWS/ECS", "NetworkIn", "ClusterName", "strapi-cluster"],
            ["AWS/ECS", "NetworkOut", "ClusterName", "strapi-cluster"]
          ],
          period = 300,
          stat   = "Average",
          region = "us-east-1",
          title  = "Strapi ECS Metrics"
        }
      }
    ]
  })
}
