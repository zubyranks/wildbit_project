// Resource #14
//Create security group for  LB to allow TCP/80 & TCP/443 and outbound to all
resource "aws_security_group" "lb_sg" {
  provider    = aws.region_master
  name        = "lb_sg"
  vpc_id      = aws_vpc.vpc_master.id
  description = "Allow TCP/80, 443 & traffic to Jenkin Master SG"
  ingress {
    description = "Allow TLS/443 from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow TCP/80 from internet and redirection to 443"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sg_LB_allow_tcp"
  }
}

// Resource #15
// Create security group for jenkins master to allow all from TCP/8080 LB, TCP/22 from IP US east-1 
resource "aws_security_group" "jenkins_master_sg" {
  provider    = aws.region_master
  name        = "jenkins_master_sg"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description     = "Allow TCP/80 from LB"
    from_port       = var.webserver_port
    to_port         = var.webserver_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
  ingress {
    description = "Allow TCP/22 from public IP to ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "Allow all from us west-2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sg_jenkins_master"
  }
}

// Resource #16
#Create security group for jenkins worker to allow all from jenkins master & TCP/22 from public IP
resource "aws_security_group" "jenkins_worker_sg" {
  provider    = aws.region_worker
  name        = "jenkins_worker_sg"
  description = "Allow all from jenkins master"
  vpc_id      = aws_vpc.vpc_master_worker.id

  ingress {
    description = "Allow all from jenkins master"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }
  ingress {
    description = "Allow TCP/22 from public IP to ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sg_jenkins_worker"
  }
}
