
terraform {
  backend "s3" {}
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.10"
}

provider "cloudflare" {}

data "cloudflare_accounts" "self" {
  name = var.cloudflare_account_name
}

locals {
  cloudflare_account_id = data.cloudflare_accounts.self.accounts[0].id
}