#----------------------------------------------------------
#EC2
#----------------------------------------------------------
#DB用EC2作成
resource "aws_instance" "EC2_DB_Childcare" {
    ami = "ami-03ed279742109860b"
    instance_type = "t2.micro"
    key_name = "zenno-test"
    vpc_security_group_ids = [
      aws_security_group.SG_DB_Childcare.id
    ]
    subnet_id = aws_subnet.private-a.id
    associate_public_ip_address = "false"

    tags = {
        Name = "EC2_DB_Childcare"
        System = "CC"
    }
}

#----------------------------------------------------------
#ALB
#----------------------------------------------------------
#ALB
resource "aws_lb" "ALB_Childcare" {
  name                       = "ALB-Childcare"
  security_groups            = [aws_security_group.SG_ALB_Childcare.id]
  subnets                    = [aws_subnet.private-a.id,aws_subnet.private-c.id]
  internal                   = false
  enable_deletion_protection = false
  tags = {
      Name = "ALB_Childcare"
      System = "CC"
  }
}

#ターゲットグループ
resource "aws_lb_target_group" "TG_Childcare_Blue" {
  name     = "TG-Childcare"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc_Childcare.id

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

resource "aws_lb_target_group" "TG_Childcare_Green" {
  name     = "TG-Childcare"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc_Childcare.id

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
resource "aws_alb_listener" "alb-blue" {
  load_balancer_arn = aws_lb.ALB_Childcare.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "443"
      message_body = "forbidden"
    }
  }
}

resource "aws_lb_listener_rule" "http_header_based_routing" {
  listener_arn = aws_alb_listener.alb-blue.arn
  priority = 10

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.TG_Childcare_Blue.arn
  }

  condition {
    http_header {
      http_header_name = "alb-header"
      values           = "bft"
    }
  }
}