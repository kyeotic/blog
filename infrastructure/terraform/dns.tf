data "aws_route53_zone" "base" {
  name         = "${var.hosted_zone_name}."
  private_zone = false
}

provider "aws" {
  region = "us-east-1"
  alias  = "certificates"
}

provider "aws" {
  region = var.region
  alias  = "dns"
}

module "cert" {
  source = "github.com/azavea/terraform-aws-acm-certificate?ref=3.0.0"

  providers = {
    aws.acm_account     = aws.certificates
    aws.route53_account = aws.dns
  }

  domain_name                       = local.domain_name
  hosted_zone_id                    = data.aws_route53_zone.base.zone_id
  validation_record_ttl             = "60"
  allow_validation_record_overwrite = true
}

resource "aws_route53_record" "domain" {
  name    = local.domain_name
  zone_id = data.aws_route53_zone.base.zone_id
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.website_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.website_cdn.hosted_zone_id
    evaluate_target_health = true
  }
}
