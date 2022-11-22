output "management_instance_public_ip" {
  value = aws_instance.management.public_ip
}

#output "app_instance_private_ip" {
#  value = aws_instance.app.private_ip
#}

#output "admin_instance_private_ip" {
#  value = aws_instance.admin.private_ip
#}

output "db_instance_endpoint" {
  #value = aws_db_instance.db.endpoint
  value = aws_rds_cluster.this.endpoint
}

#output "api_app_runner_url" {
#  value = aws_apprunner_service.api.service_url
#}

#output "admin_app_runner_url" {
#  value = aws_apprunner_service.admin.service_url
#}