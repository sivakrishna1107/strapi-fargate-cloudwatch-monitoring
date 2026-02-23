variable "ecr_repo_url" {
  description = "ECR repository URL for Strapi image"
  type        = string
}

variable "database_url" {
  description = "Strapi DATABASE_URL"
  type        = string
}

variable "jwt_secret" {
  description = "Strapi JWT_SECRET"
  type        = string
}
