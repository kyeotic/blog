data "aws_iam_policy_document" "website_s3_policy" {
  statement {
    sid       = "bucket_policy_site_main"
    actions   = ["s3:GetObject"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.website_origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name
  acl    = "private"
  policy = data.aws_iam_policy_document.website_s3_policy.json

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = {}

  force_destroy = true
}

resource "aws_cloudfront_origin_access_identity" "website_origin_access_identity" {
  comment = "site ${terraform.workspace} Access Identity"
}


resource "aws_cloudfront_distribution" "website_cdn" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"

  # http_version = "http2"

  origin {
    origin_id = "origin-bucket-${aws_s3_bucket.site.id}"

    # domain_name = "${aws_s3_bucket.site.website_endpoint}"
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website_origin_access_identity.cloudfront_access_identity_path
    }
  }
  default_root_object = "index.html"
  # custom_error_response {
  #   error_code = "404"

  #   # error_caching_min_ttl = "360"
  #   response_code      = "200"
  #   response_page_path = "/index.html"
  # }
  # custom_error_response {
  #   error_code = "403"

  #   # error_caching_min_ttl = "360"
  #   response_code      = "200"
  #   response_page_path = "/index.html"
  # }
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = "true"

      cookies {
        forward = "none"
      }
    }

    min_ttl          = "0"
    default_ttl      = "300"  //3600
    max_ttl          = "1200" //86400
    target_origin_id = "origin-bucket-${aws_s3_bucket.site.id}"

    // This redirects any HTTP request to HTTPS. Security first!
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge.qualified_arn
      include_body = false
    }
  }
  ordered_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = "true"

      cookies {
        forward = "none"
      }
    }

    min_ttl          = "0"
    default_ttl      = "0"
    max_ttl          = "0"
    target_origin_id = "origin-bucket-${aws_s3_bucket.site.id}"
    path_pattern     = "/index.html"

    // This redirects any HTTP request to HTTPS. Security first!
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = module.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
  aliases = [local.domain_name]
  lifecycle {
    ignore_changes = [tags]
  }
}