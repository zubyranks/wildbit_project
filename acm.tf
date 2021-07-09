// Resource #21
//Create ACM certificate resource that allows requesting and management of certificates 
// from the Amazon Certificate Manager via DNS (Route53).
resource "aws_acm_certificate" "jenkins-lb-https" {
  provider          = aws.region_master
  domain_name       = join(".", ["jenkins", data.aws_route53_zone.dns.name])
  validation_method = "DNS"
  tags = {
    Name        = "jenkins-ACM"
    Environment = "dev"
  }
}

// Resource #23
// Validates ACM Issued Certificate via Route53
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.region_master
  certificate_arn         = aws_acm_certificate.jenkins-lb-https.arn
  for_each                = aws_route53_record.certificate_validation
  validation_record_fqdns = [aws_route53_record.certificate_validation[each.key].fqdn]

}
