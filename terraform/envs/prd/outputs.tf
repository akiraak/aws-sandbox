output "management_instance_public_ip" {
  value = module.awssandbox.management_instance_public_ip
}

#output "app_instance_private_ip" {
#  value = module.cabo.app_instance_private_ip
#}

#output "admin_instance_private_ip" {
#  value = module.cabo.admin_instance_private_ip
#}

output "db_instance_endpoint" {
  value = module.awssandbox.db_instance_endpoint
}

#output "api_app_runner_url" {
#  value = module.cabo.api_app_runner_url
#}

#output "admin_app_runner_url" {
#  value = module.cabo.admin_app_runner_url
#}
