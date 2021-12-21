#----------------------------------------------------------
#VPC
#----------------------------------------------------------
resource "aws_vpc" "vpc_Childcare_Service" {
    cidr_block = "172.26.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "false"
    tags = {
      Name = "VPC_Childcare_Service"
      System = "CCS"
    }
}


#----------------------------------------------------------
#サブネット
#----------------------------------------------------------

#パブリックA
resource "aws_subnet" "public-a" {
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    cidr_block = "10.1.1.0/24"
    availability_zone = "ap-northeast-1a"
}

#パブリックC
resource "aws_subnet" "public-c" {
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    cidr_block = "10.1.2.0/24"
    availability_zone = "ap-northeast-1c"
}

#プライベートA
resource "aws_subnet" "private-a" {
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    cidr_block = "10.10.1.0/24"
    availability_zone = "ap-northeast-1a"
}

#プライベートC
resource "aws_subnet" "private-c" {
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    cidr_block = "10.10.2.0/24"
    availability_zone = "ap-northeast-1c"
}


#----------------------------------------------------------
#インターネットゲートウェイ
#----------------------------------------------------------
resource "aws_internet_gateway" "igw_Childcare_Service" {
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    tags = {
        Name = "igw_Childcare_Service"
        System = "CCS"
    }
}



#----------------------------------------------------------
#NATゲートウェイ
#----------------------------------------------------------
#NAT用EIP
resource "aws_eip" "eip_natgw_Childcare_Service" {
  vpc = true

  tags = {
    Name = "eip_natgw_Childcare_Service"
    System = "CCS"
  }
}

#NATゲートウェイ
resource "aws_nat_gateway" "NATgw_Childcare_Service" {
  allocation_id = aws_eip.eip_natgw_Childcare_Service.id
  subnet_id     = aws_subnet.private-a.id

  tags = {
    Name = "NATgw_Childcare_Service"
    System = "CCS"
  }
}

#----------------------------------------------------------
#ルートテーブル
#----------------------------------------------------------
#インターネットゲートウェイ向けルートテーブル
resource "aws_route_table" "public-route_Childcare_Service" {
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_Childcare_Service.id
    }
}

#紐づけ
resource "aws_route_table_association" "puclic-a" {
    subnet_id = aws_subnet.public-a.id
    route_table_id = aws_route_table.public-route_Childcare_Service.id
}

resource "aws_route_table_association" "puclic-c" {
    subnet_id = aws_subnet.public-c.id
    route_table_id = aws_route_table.public-route_Childcare_Service.id
}

#NATゲートウェイ向けルートテーブル
resource "aws_route_table" "private-route_Childcare_Service" {
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.NATgw_Childcare_Service.id
    }
}

#紐づけ
resource "aws_route_table_association" "private-a" {
    subnet_id = aws_subnet.private-a.id
    route_table_id = aws_route_table.private-route_Childcare_Service.id
}

resource "aws_route_table_association" "private-c" {
    subnet_id = aws_subnet.private-c.id
    route_table_id = aws_route_table.private-route_Childcare_Service.id
}


#----------------------------------------------------------
#セキュリティグループ
#----------------------------------------------------------
#DB用セキュリティグループ
resource "aws_security_group" "SG_DB_Childcare_Service" {
    name = "SG_DB_Childcare_Service"
    description = "Allow DB inbound traffic"
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    tags = {
      Name = "SG_DB_Childcare_Service"
      System = "CCS"
    }
}

#ルール
resource "aws_security_group_rule" "InboundRule_DBPort_Fargate_Childcare_Service" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = [
    "10.10.1.0/24"
  ]

  # ここでweb_serverセキュリティグループに紐付け
  security_group_id = aws_security_group.SG_DB_Childcare_Service.id
}

#コンテナ用セキュリティグループ
resource "aws_security_group" "SG_Fargate_Childcare_Service" {
    name = "SG_Fargate_Childcare_Service"
    description = "Allow Fargate inbound traffic"
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    tags = {
      Name = "SG_Fargate_Childcare_Service"
      System = "CCS"
    }
}
#ルール
resource "aws_security_group_rule" "InboundRule_ALBSubnet-a_Fargate_Childcare_Service" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = [
    "10.10.1.0/24"
  ]

  # ここでweb_serverセキュリティグループに紐付け
  security_group_id = aws_security_group.SG_Fargate_Childcare_Service.id
}

#ルール
resource "aws_security_group_rule" "InboundRule_ALBSubnet-c_Fargate_Childcare_Service" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = [
    "10.10.2.0/24"
  ]

  # ここでweb_serverセキュリティグループに紐付け
  security_group_id = aws_security_group.SG_Fargate_Childcare_Service.id
}

#ALB用セキュリティグループ
resource "aws_security_group" "SG_ALB_Childcare_Service" {
    name = "SG_ALB_Childcare_Service"
    description = "Allow ALB inbound traffic"
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    tags = {
      Name = "SG_ALB_Childcare_Service"
      System = "CCS"
    }
}