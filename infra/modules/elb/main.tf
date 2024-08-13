
#ALB
resource "aws_lb" "tf_lb_test" {
  name               = "tf-lb-test"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf_sg_main.id]
  subnets = [aws_subnet.tf_subnet_main.id, aws_subnet.tf_subnet_secondary.id]
  #subnets            = [for subnet in aws_subnet.tf_subnet_main : subnet.id]


  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "dev"
  }
}

#Target Group
resource "aws_lb_target_group" "tf_tg_main" {
  name     = "tf-tg-main"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.tf_vpc_main.id
}

# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.tf_lb_test.arn
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf_tg_main.arn
  }
}

# resource "aws_lb_listener" "front_end_secured" { # Requires an SSL Certificate - Lets Encrypt?
#   load_balancer_arn = aws_lb.tf_lb_test.arn
#   port              = "80"
#   protocol          = "HTTPS"
#   #ssl_policy        = "ELBSecurityPolicy-2016-08"
#   #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tf_tg_main.arn
#   }
# }

