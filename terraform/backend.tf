terraform {
  backend "s3" {
    bucket  = "sejal-strapi-fargate-task"
    key     = "sejal-fargate/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

