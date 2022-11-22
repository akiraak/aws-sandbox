# ================================================
# EC2: AMI
# ================================================
data aws_ssm_parameter amzn2_ami {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data aws_ssm_parameter amzn2_arm_ami {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended/image_id"
}
