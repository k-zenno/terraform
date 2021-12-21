
variable "images" {
    default = "ami-03ed279742109860b"
}

#DB用EC2作成
resource "aws_instance" "NRI_EC2_Zenno_20201002" {
    ami = var.images
    instance_type = "t2.medium"
    key_name = "uk-key"
    vpc_security_group_ids = [
      aws_security_group.NRI_SG_Zenno_20201002.id
    ]
    subnet_id = aws_subnet.public-a.id
    associate_public_ip_address = "true"

    tags = {
        Name = "NRI_EC2_Zenno_20201002"
        Project = "NRI"
        Month = "20201002_202011"
        AutoStop = "ON"
    }
}