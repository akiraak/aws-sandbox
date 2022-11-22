# ================================================
# Subnet: Public management
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
# Security group: management
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

# ================================================
# EC2: management
# ================================================
resource "aws_instance" "management" {
  #ami                         = data.aws_ssm_parameter.amzn2_ami.value
  ami                         = data.aws_ssm_parameter.amzn2_arm_ami.value
  vpc_security_group_ids      = [aws_security_group.management.id]
  subnet_id                   = aws_subnet.public_management_1.id
  key_name                    = aws_key_pair.management.key_name
  instance_type               = var.instance_type_management
  associate_public_ip_address = "true"

  tags = {
    Name = "${var.name}-management"
  }

  user_data = <<EOF
    #!/bin/bash
    sudo yum -y update
    sudo yum install -y mariadb-server git
  EOF
}

resource "aws_key_pair" "management" {
  key_name   = "${var.name}-key-management"
  public_key = file(var.public_key_path_management)
}
