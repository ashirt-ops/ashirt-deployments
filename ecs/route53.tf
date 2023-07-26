# Data provider uses existing primary zone for a route53 domain

data "aws_route53_zone" "ashirt" {
  name = var.domain
}

# ACM cert and deps

resource "aws_acm_certificate" "ashirt" {
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ashirt-cert" {
  for_each = {
    for dvo in aws_acm_certificate.ashirt.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.ashirt.zone_id
}

# Target for the browser and ashirt application

resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.ashirt.zone_id
  name    = "ashirt.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.frontend.dns_name]
}
