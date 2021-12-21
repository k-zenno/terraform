
variable "images" {
    default = "ami-03ed279742109860b"
}

#----------------------------------------------------------
#EC2
#----------------------------------------------------------
#DB用EC2作成
resource "aws_instance" "EC2_DB_Childcare_Service" {
    ami = var.images
    instance_type = "t2.micro"
    key_name = "zenno-test"
    vpc_security_group_ids = [
      aws_security_group.SG_DB_Childcare_Service.id
    ]
    subnet_id = aws_subnet.private-a.id
    associate_public_ip_address = "true"

    tags = {
        Name = "EC2_DB_Childcare_Service"
        System = "CSS"
    }
}

#----------------------------------------------------------
#ALB
#----------------------------------------------------------
#ALB
resource "aws_lb" "ALB_Childcare_Service" {
  name                       = "ALB-Childcare-Service"
  security_groups            = aws_security_group.SG_ALB_Childcare_Service.id
  subnets                    = [aws_subnet.private-a.id,aws_subnet.private-c.id]
  internal                   = false
  enable_deletion_protection = false
  tags = {
      Name = "ALB_Childcare_Service"
      System = "CSS"
  }
}

#ターゲットグループ
resource "aws_lb_target_group" "TG_Childcare_Service" {
  name     = "TG-Childcare-Service"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc_Childcare_Service.id

  health_check {
    interval            = 30
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}

#リスナー
resource "aws_alb_listener" "alb" {
  load_balancer_arn = aws_lb.ALB_Childcare_Service.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.TG_Childcare_Service.arn
    type             = "forward"
  }
}