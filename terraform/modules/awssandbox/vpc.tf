variable "vpc" {
  default = {
    "vpc_cidr_block" = "10.0.0.0/16"
    "subnet_public_management_1_cidr_block" = "10.0.240.0/24"
    "subnet_public_management_2_cidr_block" = "10.0.241.0/24"
    "subnet_public_app_alb_1_cidr_block" = "10.0.0.0/24"
    "subnet_public_app_alb_2_cidr_block" = "10.0.1.0/24"
    "subnet_private_app_1_cidr_block" = "10.0.8.0/24"
    "subnet_private_app_2_cidr_block" = "10.0.9.0/24"
    "subnet_private_app_db_1_cidr_block" = "10.0.16.0/24"
    "subnet_private_app_db_2_cidr_block" = "10.0.17.0/24"
  }
}

# ================================================
# VPC
# ================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name}"
  }
}

# ================================================
# Public Root table & Internet gateway
# ================================================
resource "aws_internet_gateway" "main" {
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
  gateway_id             = aws_internet_gateway.main.id
}

# ================================================
# Private Root table & NAT gateway & Elastic IP
# ================================================
resource "aws_eip" "nat" {
  vpc = true
  tags = {
    Name = "${var.name}-nat"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_alb_1.id

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

# ================================================
# Public Subnet: ALB
# ================================================
resource "aws_subnet" "public_alb_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.subnet_public_app_alb_1_cidr_block
  availability_zone = var.az_1
  tags = {
    Name = "${var.name}-public-app-alb-1"
  }
}

resource "aws_subnet" "public_alb_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.subnet_public_app_alb_2_cidr_block
  availability_zone = var.az_2
  tags = {
    Name = "${var.name}-public-app-alb-2"
  }
}

resource "aws_route_table_association" "public_alb_1" {
  subnet_id      = aws_subnet.public_alb_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_alb_2" {
  subnet_id      = aws_subnet.public_alb_2.id
  route_table_id = aws_route_table.public.id
}

# ================================================
# Private Subnet: APP
# ================================================
resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.subnet_private_app_1_cidr_block
  availability_zone = var.az_1
  tags = {
    Name = "${var.name}-private-app-1"
  }
}

resource "aws_subnet" "private_app_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.subnet_private_app_2_cidr_block
  availability_zone = var.az_2
  tags = {
    Name = "${var.name}-private-app-2"
  }
}

resource "aws_route_table_association" "private_app_1" {
  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_app_2" {
  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.private.id
}

# ================================================
# Private Subnet: DB
# ================================================
resource "aws_subnet" "private_app_db_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.subnet_private_app_db_1_cidr_block
  availability_zone = var.az_1
  tags = {
    Name = "${var.name}-private-app-db-1"
  }
}

resource "aws_subnet" "private_app_db_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.subnet_private_app_db_2_cidr_block
  availability_zone = var.az_2
  tags = {
    Name = "${var.name}-private-app-db-2"
  }
}

# ================================================
# Public Subnet: management
# ================================================
resource "aws_subnet" "public_management_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.subnet_public_management_1_cidr_block
  availability_zone = var.az_1
  tags = {
    Name = "${var.name}-public-management-1"
  }
}

resource "aws_subnet" "public_management_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc.subnet_public_management_2_cidr_block
  availability_zone = var.az_2
  tags = {
    Name = "${var.name}-public-management-2"
  }
}

resource "aws_route_table_association" "public_management_1" {
  subnet_id      = aws_subnet.public_management_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_management_2" {
  subnet_id      = aws_subnet.public_management_2.id
  route_table_id = aws_route_table.public.id
}

# ================================================
# Security Group: VPC
# ================================================
resource "aws_security_group" "vpc" {
  name                   = "${var.name}-vpc"
  vpc_id                 = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-vpc"
  }
}

# ================================================
# Security Group: WEB
# ================================================
resource "aws_security_group" "web" {
  name                   = "${var.name}-web"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = false

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-web"
  }
}

# http
resource "aws_security_group_rule" "alb_permit_from_internet_http" {
  security_group_id = aws_security_group.web.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "permit from internet for http."
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
}

# https
resource "aws_security_group_rule" "alb_permit_from_internet_https" {
  security_group_id = aws_security_group.web.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "permit from internet for https."
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
}

# ================================================
# Security Group: DB
# ================================================
resource "aws_security_group" "db" {
  name                   = "${var.name}-db"
  vpc_id                 = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-db"
  }
}

# ================================================
# Security Group: management
# ================================================
resource "aws_security_group" "management" {
  name                   = "${var.name}-management"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = false

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-management"
  }
}

# ssh
resource "aws_security_group_rule" "app_permit_ssh" {
  security_group_id = aws_security_group.management.id
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "22"
  to_port           = "22"
}
