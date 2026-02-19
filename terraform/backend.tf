terraform {
  backend "s3" {
    bucket  = "strapi-fargate-task"
    key     = "fargate/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

