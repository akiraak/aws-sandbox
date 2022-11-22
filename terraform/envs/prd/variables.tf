variable "main" {
  default = {
    "name" = "awssandbox"
    "route53_zone_name" = "awssandbox.mspv2.com"
    "api_subdomain" = "api.awssandbox.mspv2.com"
    "region" = "us-west-2"
    "az_1" = "us-west-2a"
    "az_2" = "us-west-2c"
    #"acm_certificate_arn_app" = "arn:aws:acm:us-west-2:131477731930:certificate/20f1a4a8-7f64-4674-b16d-84d37a135612"
    #"acm_certificate_arn_admin" = ""
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
