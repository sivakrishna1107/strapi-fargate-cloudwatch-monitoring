################################################
# DEFAULT VPC
################################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

################################################
# APPLICATION LOAD BALANCER
################################################

resource "aws_lb" "alb" {
  name               = "strapi-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb_sg.id]
}

################################################
# TARGET GROUP
################################################

resource "aws_lb_target_group" "tg" {
  name        = "strapi-tg"
  port        = 1337
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id
}

################################################
# LISTENER
################################################

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
