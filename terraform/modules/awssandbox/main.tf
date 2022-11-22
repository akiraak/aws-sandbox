# ================================================
# VPC
# ================================================
variable "vpc" {
  default = {
    "vpc_cidr_block" = "10.0.0.0/16"
    "subnet_public_management_1_cidr_block" = "10.0.240.0/24"
    "subnet_public_management_2_cidr_block" = "10.0.241.0/24"
    "subnet_public_app_alb_1_cidr_block" = "10.0.0.0/24"
    "subnet_public_app_alb_2_cidr_block" = "10.0.1.0/24"
    #"subnet_private_app_1_cidr_block" = "10.0.8.0/24"
    #"subnet_private_app_2_cidr_block" = "10.0.9.0/24"
    "subnet_private_app_db_1_cidr_block" = "10.0.16.0/24"
    "subnet_private_app_db_2_cidr_block" = "10.0.17.0/24"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name}"
  }
}

# ================================================
# Internet gateway & Root table
# ================================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.name}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# ================================================
# NAT gateway & Elastic IP & Root table
# ================================================
/*
resource "aws_eip" "ngw" {
  vpc = true
  tags = {
    Name = "${var.name}-ngw"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public_app_alb_1.id

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    nat_gateway_id = aws_nat_gateway.main.id
    cidr_block = "0.0.0.0/0"
  }
  tags = {
    Name = "${var.name}-private"
  }
}
*/


