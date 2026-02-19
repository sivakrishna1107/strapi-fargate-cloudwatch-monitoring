output "cluster_name" {
  value = aws_ecs_cluster.sejal_cluster_siva.name
}

output "service_name" {
  value = aws_ecs_service.sejal_service_siva.name
}

output "rds_endpoint" {
  value = aws_db_instance.sejal_db_siva.address
}

