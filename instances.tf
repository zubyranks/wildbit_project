// Obtain linux AMI ID using SSM Parameter endpoint in us-east1
data "aws_ssm_parameter" "linux_ami" {
  provider = aws.region_master
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

// Obtain linux AMI ID using SSM Parameter endpoint in us-west2
data "aws_ssm_parameter" "linux_ami_worker" {
  provider = aws.region_worker
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

// Resource #17
// Create a public key for us-east1
resource "aws_key_pair" "master_key" {
  provider   = aws.region_master
  key_name   = "frankfurt"
  public_key = file("~/.ssh/id_rsa.pub")
}

// Resource #18
// Create a public key for us-west2
resource "aws_key_pair" "worker_key" {
  provider   = aws.region_worker
  key_name   = "frankfurt"
  public_key = file("~/.ssh/id_rsa.pub")
}

// Resource #19
// create jenkins master EC2 instances
resource "aws_instance" "jenkins_master" {
  provider                    = aws.region_master
  ami                         = data.aws_ssm_parameter.linux_ami.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.master_key.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_master_sg.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet_1.id

  tags = {

    Name = "jenkins_master_tf"
  }
  depends_on = [aws_main_route_table_association.set_master_default_rt_assoc]

  #The code below is ONLY the provisioner block which needs to be
  #inserted inside the resource block for Jenkins EC2 worker in Terraform

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region_master} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/jenkins-master-sample.yml
EOF
  }


}

// Resource #20
// create jenkins worker EC2 instances
resource "aws_instance" "jenkins_worker" {
  provider                    = aws.region_worker
  count                       = var.workers_count
  ami                         = data.aws_ssm_parameter.linux_ami_worker.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.worker_key.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_worker_sg.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet_1_worker.id

  tags = {

    Name = join(" ", ["jenkins_worker_tf", count.index + 1])
  }
  depends_on = [aws_main_route_table_association.set_worker_default_rt_assoc, aws_instance.jenkins_master]

  #The code below is ONLY the provisioner block which needs to be
  #inserted inside the resource block for Jenkins EC2 worker in Terraform

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region_worker} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/jenkins-worker-sample.yml
EOF
  }
}
