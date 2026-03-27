#-------------------------------------------
# Required variables (do not add defaults here!)
#-------------------------------------------

variable "cloudflare_account_name" {
  default = "tim@kye.dev"
}

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

variable "pages_project_name" {
  type    = string
  default = "kye-blog"
}
