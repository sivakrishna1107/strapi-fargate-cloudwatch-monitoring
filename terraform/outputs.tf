output "cluster_name" {
  value = aws_ecs_cluster.sejal_cluster.name
}

output "service_name" {
  value = aws_ecs_service.sejal_service.name
}

