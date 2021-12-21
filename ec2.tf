
variable "images" {
    default = "ami-03ed279742109860b"
}

#DB用EC2作成
resource "aws_instance" "EC2_DB_DB_Childcare_Service" {
    ami = var.images
    instance_type = "t2.micro"
    key_name = "zenno-test"
    vpc_security_group_ids = [
      aws_security_group.SG_DB_Childcare_Service.id
    ]
    subnet_id = aws_subnet.private-a.id
    associate_public_ip_address = "true"

    tags = {
        Name = "EC2_DB_DB_Childcare_Service"
        System = "CSS"
    }
}