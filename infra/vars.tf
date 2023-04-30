#-------------------------------------------
# Required variables (do not add defaults here!)
#-------------------------------------------

#-------------------------------------------
# Configurable variables
#-------------------------------------------
variable "region" {
  default = "us-west-2"
}

variable "domain_name" {
  default = "blog.kye.dev"
}

variable "zone_name" {
  default = "kye.dev"
}

variable "deno_deploy_a" {
  default = "34.120.54.55"
}

variable "deno_deploy_aaaa" {
  default = "2600:1901:0:6d85::"
}

variable "deno_deploy_acme" {
  default = {
    name  = "_acme-challenge"
    value = "2a49f3a51c08eae6d5e5a82e._acme.deno.dev."
  }
}
