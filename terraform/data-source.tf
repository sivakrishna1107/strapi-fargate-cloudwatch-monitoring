# Get Default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all default subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
