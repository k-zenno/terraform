#----------------------------------------------------------
#EC2
#----------------------------------------------------------
#DB用EC2
#ネットワークインターフェース
resource "aws_network_interface" "db" {
  subnet_id   = aws_subnet.private-a.id
  private_ips = ["10.0.11.100"]
  security_groups = [aws_security_group.SG_DB_Childcare.id]

  tags = {
    Name = "db_interface"
  }
}

#インスタンス
resource "aws_instance" "EC2_DB_Childcare" {
    ami = "ami-0ac7b96f31f016d3e"
    instance_type = "t2.micro"
    key_name = "CC-Key"
    iam_instance_profile = aws_iam_instance_profile.systems_manager.name
    

    network_interface {
    network_interface_id = aws_network_interface.db.id
    device_index         = 0
    }

    user_data = data.template_file.script.rendered

    tags = {
        Name = "EC2_DB_Childcare"
        System = "CC"
    }
}

variable "db_pass" {}

data "template_file" "script" {
  template = file("config/PasswdAuthSet.sh")

  vars = {
    pass = var.db_pass
  }
}

#----------------------------------------------------------
#ALB
#----------------------------------------------------------
#ALB
resource "aws_alb" "ALB_Childcare" {
  name                       = "ALB-Childcare"
  security_groups            = [aws_security_group.SG_ALB_Childcare.id]
  subnets                    = [aws_subnet.public-a.id,aws_subnet.public-c.id]
  internal                   = false
  enable_deletion_protection = false
  tags = {
      Name = "ALB_Childcare"
      System = "CC"
  }
}

#ターゲットグループ
resource "aws_alb_target_group" "TG_Childcare_Blue" {
  name     = "TG-Childcare-Blue"
  port     = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc_Childcare.id

  health_check {
    interval            = 30
    path                = "/api/v1/health"
    port                = 8080
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}

resource "aws_alb_target_group" "TG_Childcare_Green" {
  name     = "TG-Childcare-Green"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc_Childcare.id

  health_check {
    interval            = 30
    path                = "/api/v1/health"
    port                = 8080
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}


#リスナー(Blue)
resource "aws_alb_listener" "alb-blue" {
  load_balancer_arn = aws_alb.ALB_Childcare.arn
  port              = "8080"
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

#リスナールール(Blue)
resource "aws_alb_listener_rule" "http_header_based_routing_green" {
  listener_arn = aws_alb_listener.alb-green.arn
  priority = 11

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.TG_Childcare_Green.arn
  }

  condition {
    http_header {
      http_header_name = "alb-header"
      values           = ["bft"]
    }
  }

  lifecycle {
    ignore_changes = [
      action["target_group_arn"],
    ]
  }
}



#リスナー(Green)
resource "aws_alb_listener" "alb-green" {
  load_balancer_arn = aws_alb.ALB_Childcare.arn
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

#リスナールール(Green)
resource "aws_alb_listener_rule" "http_header_based_routing_blue" {
  listener_arn = aws_alb_listener.alb-blue.arn
  priority = 10

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.TG_Childcare_Green.arn
  }

  condition {
    http_header {
      http_header_name = "alb-header"
      values           = ["bft"]
    }
  }
  lifecycle {
    ignore_changes = [
      action["target_group_arn"],
    ]
  }
}

