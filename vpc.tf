#----------------------------------------------------------
#VPC
#----------------------------------------------------------
resource "aws_vpc" "vpc_Childcare" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "false"
    tags = {
      Name = "VPC_Childcare"
      System = "CC"
    }
}


#----------------------------------------------------------
#サブネット
#----------------------------------------------------------

#パブリックA
resource "aws_subnet" "public-a" {
    vpc_id = aws_vpc.vpc_Childcare.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-1a"
    tags = {
      Name = "Subnet_public-a_Childcare"
      System = "CC"
    }
}

#パブリックC
resource "aws_subnet" "public-c" {
    vpc_id = aws_vpc.vpc_Childcare.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-northeast-1c"
    tags = {
      Name = "Subnet_public-c_Childcare"
      System = "CC"
    }
}

#プライベートA
resource "aws_subnet" "private-a" {
    vpc_id = aws_vpc.vpc_Childcare.id
    cidr_block = "10.0.11.0/24"
    availability_zone = "ap-northeast-1a"
    tags = {
      Name = "Subnet_private-a_Childcare"
      System = "CC"
    }
}

#プライベートC
resource "aws_subnet" "private-c" {
    vpc_id = aws_vpc.vpc_Childcare.id
    cidr_block = "10.0.12.0/24"
    availability_zone = "ap-northeast-1c"
    tags = {
      Name = "Subnet_private-c_Childcare"
      System = "CC"
    }
}


#----------------------------------------------------------
#インターネットゲートウェイ
#----------------------------------------------------------
resource "aws_internet_gateway" "igw_Childcare" {
    vpc_id = aws_vpc.vpc_Childcare.id
    tags = {
        Name = "igw_Childcare"
        System = "CC"
    }
}



#----------------------------------------------------------
#NATゲートウェイ
#----------------------------------------------------------
#NAT用EIP
resource "aws_eip" "eip_natgw_Childcare" {
  vpc = true

  tags = {
    Name = "eip_natgw_Childcare"
    System = "CC"
  }
}

#NATゲートウェイ
resource "aws_nat_gateway" "NATgw_Childcare" {
  allocation_id = aws_eip.eip_natgw_Childcare.id
  subnet_id     = aws_subnet.private-a.id

  tags = {
    Name = "NATgw_Childcare"
    System = "CC"
  }
}

#----------------------------------------------------------
#ルートテーブル
#----------------------------------------------------------
#インターネットゲートウェイ向けルートテーブル
resource "aws_route_table" "public-route_Childcare" {
    vpc_id = aws_vpc.vpc_Childcare.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_Childcare.id
    }
    tags = {
        Name = "public-route_Childcare"
        System = "CC"
    }
}

#紐づけ
resource "aws_route_table_association" "puclic-a" {
    subnet_id = aws_subnet.public-a.id
    route_table_id = aws_route_table.public-route_Childcare.id
}

resource "aws_route_table_association" "puclic-c" {
    subnet_id = aws_subnet.public-c.id
    route_table_id = aws_route_table.public-route_Childcare.id
}

#NATゲートウェイ向けルートテーブル
resource "aws_route_table" "private-route_Childcare" {
    vpc_id = aws_vpc.vpc_Childcare.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.NATgw_Childcare.id
    }
    tags = {
        Name = "private-route_Childcare"
        System = "CC"
    }
}

#紐づけ
resource "aws_route_table_association" "private-a" {
    subnet_id = aws_subnet.private-a.id
    route_table_id = aws_route_table.private-route_Childcare.id
}

resource "aws_route_table_association" "private-c" {
    subnet_id = aws_subnet.private-c.id
    route_table_id = aws_route_table.private-route_Childcare.id
}


#----------------------------------------------------------
#セキュリティグループ
#----------------------------------------------------------
#DB用セキュリティグループ
resource "aws_security_group" "SG_DB_Childcare" {
    name = "SG_DB_Childcare"
    description = "Allow DB inbound traffic"
    vpc_id = aws_vpc.vpc_Childcare.id
    tags = {
      Name = "SG_DB_Childcare"
      System = "CC"
    }
}

#ルール
resource "aws_security_group_rule" "InboundRule_DBPort_Childcare" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = [
    "10.10.1.0/24"
  ]

  security_group_id = aws_security_group.SG_DB_Childcare.id
}

#コンテナ用セキュリティグループ
resource "aws_security_group" "SG_Fargate_Childcare" {
    name = "SG_Fargate_Childcare"
    description = "Allow Fargate inbound traffic"
    vpc_id = aws_vpc.vpc_Childcare.id
    tags = {
      Name = "SG_Fargate_Childcare"
      System = "CC"
    }
}
#ルール
resource "aws_security_group_rule" "InboundRule_ALBSubnet-a_Childcare" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = [
    "10.10.1.0/24"
  ]

  security_group_id = aws_security_group.SG_Fargate_Childcare.id
}

#ルール
resource "aws_security_group_rule" "InboundRule_ALBSubnet-c_Childcare" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = [
    "10.10.2.0/24"
  ]

  security_group_id = aws_security_group.SG_Fargate_Childcare.id
}

#ALB用セキュリティグループ
resource "aws_security_group" "SG_ALB_Childcare" {
    name = "SG_ALB_Childcare"
    description = "Allow ALB inbound traffic"
    vpc_id = aws_vpc.vpc_Childcare.id
    tags = {
      Name = "SG_ALB_Childcare"
      System = "CC"
    }
}