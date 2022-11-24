# ================================================
# RDS SSM
# ================================================
data "aws_ssm_parameter" "db_name" {
  name = "${var.ssm_parameter_store_base}/db_name"
}

data "aws_ssm_parameter" "db_user" {
  name = "${var.ssm_parameter_store_base}/db_user"
}

data "aws_ssm_parameter" "db_password" {
  name = "${var.ssm_parameter_store_base}/db_password"
}

# ================================================
# DB Subnet: app db
# ================================================
resource "aws_db_subnet_group" "app" {
  name        = "${var.name}-app"
  subnet_ids  = [
    "${aws_subnet.private_app_db_1.id}",
    "${aws_subnet.private_app_db_2.id}"
  ]
  tags = {
      Name = "${var.name}-app"
  }
}

/*
# ================================================
# RDS: app db
# ================================================
resource "aws_db_instance" "db" {
  identifier          = "${var.name}-app"
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "8.0.23"
  instance_class      = var.db_instance_type_app
  #db_name             = "cabo_app"
  #username            = "root"
  #password            = "rootroot"
  db_name             = data.aws_ssm_parameter.db_name.value
  username            = data.aws_ssm_parameter.db_user.value
  password            = data.aws_ssm_parameter.db_password.value
  skip_final_snapshot = true
  #vpc_security_group_ids = [aws_security_group.app_db.id, aws_security_group.app_db_for_admin_vpcconnector.id]
  vpc_security_group_ids = [aws_security_group.app_db.id]
  db_subnet_group_name   = aws_db_subnet_group.app.name
}
*/

####################################################
# RDS Cluster
####################################################

resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.name}-database-cluster"

  db_subnet_group_name   = aws_db_subnet_group.app.name
  vpc_security_group_ids = [aws_security_group.db.id]

  engine = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.01.0"
  port   = "3306"

  database_name   = data.aws_ssm_parameter.db_name.value
  master_username = data.aws_ssm_parameter.db_user.value
  master_password = data.aws_ssm_parameter.db_password.value

  skip_final_snapshot = true

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name
}

####################################################
# RDS Cluster Instance
####################################################

resource "aws_rds_cluster_instance" "this" {
  identifier         = "${var.name}-database-cluster-instance"
  cluster_identifier = aws_rds_cluster.this.id

  engine = aws_rds_cluster.this.engine
  engine_version = aws_rds_cluster.this.engine_version

  instance_class = var.db_instance_type_app
  db_subnet_group_name = aws_rds_cluster.this.db_subnet_group_name
}

####################################################
# RDS cluster config
####################################################
resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.name}-database-cluster-parameter-group"
  family = "aurora-mysql8.0"

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }
}

####################################################
# Create SSM DB url
####################################################
resource "aws_ssm_parameter" "database_url" {
  name  = "${var.ssm_parameter_store_base}/db_url"
  type  = "String"
  value = aws_rds_cluster.this.endpoint
}
