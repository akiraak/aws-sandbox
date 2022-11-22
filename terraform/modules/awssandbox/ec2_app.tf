# ================================================
# Subnet: Private app
# ================================================
/*
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
*/

# ================================================
# Security group: app
# ================================================
/*
resource "aws_security_group" "app" {
  name                   = "${var.name}-app"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = false

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-app"
  }
}

# http
resource "aws_security_group_rule" "app_permit_from_app_alb_http" {
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.app_alb.id
  description              = "permit from alb."
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "80"
  to_port                  = "80"
}

# ssh
resource "aws_security_group_rule" "app_permit_from_management_ssh" {
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.management.id
  description              = "permit from management."
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "22"
  to_port                  = "22"
}
*/

# ================================================
# EC2: app
# ================================================
/*
resource "aws_iam_role" "app" {
    name = "${var.name}-ir-app"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "app" {
    name = "${var.name}-irp-app"
    role = aws_iam_role.app.id
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "app" {
    name = "${var.name}-iip-app"
    role = aws_iam_role.app.name
}

resource "aws_key_pair" "app" {
  key_name   = "${var.name}-key-app"
  public_key = file(var.public_key_path_app)
}

resource "aws_instance" "app" {
  #ami                     = data.aws_ssm_parameter.amzn2_ami.value
  ami                     = data.aws_ssm_parameter.amzn2_arm_ami.value
  vpc_security_group_ids  = [aws_security_group.app.id]
  subnet_id               = aws_subnet.private_app_1.id
  key_name                = aws_key_pair.app.key_name
  instance_type           = var.instance_type_app
  iam_instance_profile    = aws_iam_instance_profile.app.name
  tags = {
    Name = "${var.name}-app"
  }
}
*/

# ================================================
# EC2: admin
# ================================================
/*
resource "aws_iam_role" "admin" {
    name = "${var.name}-ir-admin"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "admin" {
    name = "${var.name}-irp-admin"
    role = aws_iam_role.admin.id
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "admin" {
    name = "${var.name}-iip-admin"
    role = aws_iam_role.admin.name
}

resource "aws_instance" "admin" {
  #ami                     = data.aws_ssm_parameter.amzn2_ami.value
  ami                     = data.aws_ssm_parameter.amzn2_arm_ami.value
  vpc_security_group_ids  = [aws_security_group.app.id]
  subnet_id               = aws_subnet.private_app_1.id
  key_name                = aws_key_pair.app.key_name
  instance_type           = var.instance_type_admin
  iam_instance_profile    = aws_iam_instance_profile.admin.name
  tags = {
    Name = "${var.name}-admin"
  }
}
*/