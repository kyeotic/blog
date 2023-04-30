data "aws_route53_zone" "domain" {
  name = "${var.zone_name}."
}

resource "aws_route53_record" "a" {
  name    = var.domain_name
  zone_id = data.aws_route53_zone.domain.zone_id
  type    = "A"
  ttl     = 300
  records = [var.deno_deploy_a]
}

resource "aws_route53_record" "aaaa" {
  name    = var.domain_name
  zone_id = data.aws_route53_zone.domain.zone_id
  type    = "AAAA"
  ttl     = 300
  records = [var.deno_deploy_aaaa]
}

resource "aws_route53_record" "acme" {
  name    = "${var.deno_deploy_acme.name}.${var.domain_name}"
  zone_id = data.aws_route53_zone.domain.zone_id
  type    = "CNAME"
  ttl     = 300
  records = [var.deno_deploy_acme.value]
}
