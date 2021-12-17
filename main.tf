variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
    default = "ap-northeast-1"
}

provider "aws" {
    access_key = var.AWS_ACCESS_KEY
    secret_key = var.AWS_SERCRET_KEY
    region = var.region
}

#----------------------------------------------------------
#VPC
#----------------------------------------------------------
resource "aws_vpc" "vpc_Childcare_Service" {
    cidr_block = "10.1.0.0/16"
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
}


#----------------------------------------------------------
#ルートテーブル
#----------------------------------------------------------
#インターネットゲートウェイ向けルートテーブル
resource "aws_route_table" "public-route" {
    vpc_id = aws_vpc.vpc_Childcare_Service.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_Childcare_Service.id
    }
}

#紐づけ
resource "aws_route_table_association" "puclic-a" {
    subnet_id = aws_subnet.public-a.id
    route_table_id = aws_route_table.public-route.id
}

resource "aws_route_table_association" "puclic-c" {
    subnet_id = aws_subnet.public-c.id
    route_table_id = aws_route_table.public-route.id
}



