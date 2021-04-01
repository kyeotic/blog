#-------------------------------------------
# Required variables (do not add defaults here!)
#-------------------------------------------
variable subdomain_name {}
variable hosted_zone_name {}

#-------------------------------------------
# Configurable variables
#-------------------------------------------
variable "region" {
  default = "us-west-2"
}

variable "app_namespace" {
  default = "blog"
}

#-------------------------------------------
# Interpolated Values
#-------------------------------------------
locals {
  bucket_name = "${replace(var.app_namespace, "_", "-")}-${terraform.workspace}-ui"
  domain_name = "${var.subdomain_name}.${var.hosted_zone_name}"
}