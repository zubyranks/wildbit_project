// Resource #21
// Creating ALB
resource "aws_lb" "application_lb" {
  provider                   = aws.region_master
  name                       = "jenkins-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb_sg.id]
  subnets                    = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  enable_deletion_protection = false
  tags = {
    Name        = "Jenkins_LB"
    Environment = "production"
  }
}

// Resource #22
// Creating tg for ALB
resource "aws_lb_target_group" "app_lb_tg" {
  provider    = aws.region_master
  name        = "app-lb-tg"
  port        = var.webserver_port
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_master.id
  health_check {
    enabled  = true
    path     = "/"
    port     = var.webserver_port
    protocol = "HTTP"
    matcher  = "200-299"
    interval = 10
  }
  tags = {
    Name = "jenkins_target_group"
  }
}

// Resource #23
// Creating and attaching listener to ALB on port 80
resource "aws_lb_listener" "jenkins_listener" {
  provider          = aws.region_master
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"
  // Default_action decides instance action when it receives http traffic
  // listener on port 80 permanently (HTTP_301) redirects to port 443
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }

  }
}

// Resource #24
// Creating and attaching listener to ALB on port 443
resource "aws_lb_listener" "jenkins_listener_https" {
  provider          = aws.region_master
  load_balancer_arn = aws_lb.application_lb.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.jenkins-lb-https.arn
  // Default_action decides instance action when it receives redirected http traffic
  // from listener on port 80  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_lb_tg.arn
  }
}

// Resource #25
// Attaching target group to jenkins master node
resource "aws_lb_target_group_attachment" "test" {
  provider         = aws.region_master
  target_group_arn = aws_lb_target_group.app_lb_tg.arn
  target_id        = aws_instance.jenkins_master.id
  port             = var.webserver_port
}
