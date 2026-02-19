variable "region" {
  default = "us-east-1"
}

variable "image_url" {
  description = "ECR image URL"
  type        = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "execution_role_arn" {
  type = string
}

