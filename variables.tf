// Specify the user/profile tied to this project
variable "profile" {
  type    = string
  default = "terraform"
}

// Specify the region for jenkins master 
variable "region_master" {
  type    = string
  default = "us-east-1"
}

// Specify the region for jenkins worker
variable "region_worker" {
  type    = string
  default = "us-west-2"
}

// Restrict access to only those IP addresses that require it.
variable "external_ip" {
  type    = string
  default = "0.0.0.0/0"
}

// Specify the instance type for both regions
variable "instance-type" {
  type    = string
  default = "t2.micro"
}

// Specify the number of instances in the worker region
variable "workers_count" {
  type    = number
  default = 1
}

// Specify variable for web server port
variable "webserver_port" {
  type    = number
  default = 80
}

// Specify the variable for the hosted zone
variable "dns_name" {
  type    = string
  default = "testazu.cf."
}
