# ================================================
# EC2: management
# ================================================
resource "aws_instance" "management" {
  #ami                         = data.aws_ssm_parameter.amzn2_ami.value
  ami                         = data.aws_ssm_parameter.amzn2_arm_ami.value
  vpc_security_group_ids      = [
    aws_security_group.management.id,
    aws_security_group.db.id,
  ]
  subnet_id                   = aws_subnet.public_management[0].id
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
