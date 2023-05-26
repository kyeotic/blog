module "domain" {
  source      = "github.com/kyeotic/tf-deno-domain-aws"
  zone_name   = var.zone_name
  domain_name = var.domain_name
  deno_acme   = var.deno_deploy_acme
}