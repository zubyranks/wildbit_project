// Obtaining Hosted Zone from its name that will be used to create a Record Set.
data "aws_route53_zone" "dns" {
  provider = aws.region_master
  name     = var.dns_name
}

// Resource #22
// Create record in hosted zone for ACM Certificate Domain verification
resource "aws_route53_record" "certificate_validation" {
  provider = aws.region_master
  for_each = {
    for val in aws_acm_certificate.jenkins-lb-https.domain_validation_options : val.domain_name => {
      name   = val.resource_record_name
      record = val.resource_record_value
      type   = val.resource_record_type
    }
  }
  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
  zone_id = data.aws_route53_zone.dns.zone_id
}

// Resource #26
// Create Alias record from Route53 towards ALB
resource "aws_route53_record" "jenkins" {
  provider = aws.region_master
  zone_id  = data.aws_route53_zone.dns.zone_id
  name     = join(".", ["jenkins", data.aws_route53_zone.dns.name])
  type     = "A"

  alias {
    name                   = aws_lb.application_lb.dns_name
    zone_id                = aws_lb.application_lb.zone_id
    evaluate_target_health = true
  }
}
