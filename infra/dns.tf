data "cloudflare_zone" "kye_dev" {
  name = var.zone_name
}

resource "cloudflare_pages_domain" "blog" {
  account_id   = local.cloudflare_account_id
  project_name = var.pages_project_name
  domain       = var.domain_name
}

resource "cloudflare_record" "blog" {
  zone_id = data.cloudflare_zone.kye_dev.id
  name    = "blog"
  type    = "CNAME"
  content = "blog.pages.dev"
  proxied = true
}