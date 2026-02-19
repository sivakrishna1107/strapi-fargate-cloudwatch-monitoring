output "cluster_name" {
  value = aws_ecs_cluster.cluster_siva.name
}

output "service_name" {
  value = aws_ecs_service.service_siva.name
}

output "rds_endpoint" {
  value = aws_db_instance.db_siva.address
}

