resource "aws_db_subnet_group" "db_subnet_group_siva" {
  name       = "db-subnet-group-siva"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "db_siva" {
  identifier             = "db-siva"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "strapi"
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group_siva.name
  vpc_security_group_ids = [aws_security_group.ecs_sg_siva.id]
}

