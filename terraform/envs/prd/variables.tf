variable "main" {
  default = {
    "name" = "awssandbox"
    "route53_zone_name" = "awssandbox.mspv2.com"
    "api_subdomain" = "api.awssandbox.mspv2.com"
    "region" = "us-west-2"
    "azs" = ["us-west-2a", "us-west-2c"]
    "instance_type_management" = "t4g.nano"
    "instance_type_app" = "t4g.nano"
    #"instance_type_app" = "m6g.large"
    "instance_type_admin" = "t4g.nano"
    "public_key_path_management" = "../../key-awssandbox-management.pub"
    "public_key_path_app" = "../../key-awssandbox-app.pub"
    #"db_instance_type_app" = "db.m6g.large"
    "db_instance_type_app" = "db.t4g.medium"
    "auto_deploy" = true
    "ssm_parameter_store_base" = "/asandbox"
  }
}
