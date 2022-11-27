terraform {
  #required_providers {
  #  aws  = "~> 3.74"
  #}
}

provider "aws" {
  region = var.main.region
}

module "awssandbox" {
  source = "../../modules/awssandbox/"
  name = var.main.name
  route53_zone_name = var.main.route53_zone_name
  api_subdomain = var.main.api_subdomain
  region = var.main.region
  azs = var.main.azs
  instance_type_management = var.main.instance_type_management
  instance_type_app = var.main.instance_type_app
  instance_type_admin = var.main.instance_type_admin
  public_key_path_management = var.main.public_key_path_management
  public_key_path_app = var.main.public_key_path_app
  db_instance_type_app = var.main.db_instance_type_app
  auto_deploy = var.main.auto_deploy
  ssm_parameter_store_base = var.main.ssm_parameter_store_base
}
