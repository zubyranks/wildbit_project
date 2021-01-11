// Display jenkins master public ip for ssh
output "jenkins_master_instance_public_ip" {
  value = aws_instance.jenkins_master.public_ip
}


// Display jenkins workers public ip for ssh
// A for-loop within an array creates a map which then maps instance.id to public instance ip
output "jenkins_worker_instance_public_ips" {
  value = {
    for instance in aws_instance.jenkins_worker :
    instance.id => instance.public_ip
  }
}

// Display the ALB DNS from the .tfstate output file
output "LB_DNS_NAME" {
  value = aws_lb.application_lb.dns_name
}

// Display the url
output "url" {
  value = aws_route53_record.jenkins.fqdn
}

