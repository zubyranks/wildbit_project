// Resource #1
// Create first VPC that will house Jenkins Master node
resource "aws_vpc" "vpc_master" {
  provider             = aws.region_master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-jenkins"
  }
}

// Resource #2
// Create second VPC with no overlapping cidr_block for vpc peering
resource "aws_vpc" "vpc_master_worker" {
  provider             = aws.region_worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

// Resource #3
//Create IGW in master VPC
resource "aws_internet_gateway" "igw" {
  provider = aws.region_master
  vpc_id   = aws_vpc.vpc_master.id

  tags = {
    Name = "igw_master_vpc"
  }
}

// Resource #4
//Create IGW in worker VPC
resource "aws_internet_gateway" "igw_worker" {
  provider = aws.region_worker
  vpc_id   = aws_vpc.vpc_master_worker.id

  tags = {
    Name = "igw_worker_vpc"
  }
}

# Get all available AZ's for master VPC
data "aws_availability_zones" "available_master" {
  provider = aws.region_master
  state    = "available"
}

// Resource #5
// Create subnet #1 in master VPC
// element function picks the 1st AZ from the list above which is the zero index
resource "aws_subnet" "subnet_1" {
  provider          = aws.region_master
  availability_zone = element(data.aws_availability_zones.available_master.names, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "public_subnet_1"
  }
}

// Resource #6
// Create subnet #2 in master VPC
resource "aws_subnet" "subnet_2" {
  provider          = aws.region_master
  availability_zone = element(data.aws_availability_zones.available_master.names, 1)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "public_subnet_2"
  }
}

# Get all available AZ's for worker VPC
data "aws_availability_zones" "available_worker" {
  provider = aws.region_worker
  state    = "available"
}

// Resource #7
// Create subnet #1 in worker VPC
resource "aws_subnet" "subnet_1_worker" {
  provider          = aws.region_worker
  availability_zone = element(data.aws_availability_zones.available_worker.names, 0)
  vpc_id            = aws_vpc.vpc_master_worker.id
  cidr_block        = "192.168.1.0/24"

  tags = {
    Name = "public_subnet_1_worker"
  }
}

// Resource #8
//Create VPC Peering between us-east-1 & us-west-2 regions
resource "aws_vpc_peering_connection" "useast1_uswest2" {
  provider    = aws.region_master
  peer_vpc_id = aws_vpc.vpc_master_worker.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region_worker
  tags = {
    Name = "VPC Peering between useast1 & uswest2"
  }
}

// Resource #9
// Accepters VPC peering request in uswest1 from useast1 
// auto_accept enabled is only applicable to same AWS acct VPC peering
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region_worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

// Resource #10
// Create route table in master VPC 
resource "aws_route_table" "internet_route" {
  provider = aws.region_master
  vpc_id   = aws_vpc.vpc_master.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  }
  //lifecycle is added to prevent RT resource containing data from changing during a terraform create or update  
  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "master-region-priv-RT"
  }
}

// Resource #11
// Overwrite default route table of Master VPC with new RT entries 
resource "aws_main_route_table_association" "set_master_default_rt_assoc" {
  provider       = aws.region_master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}

// Resource #12
// Create route table in worker VPC 
resource "aws_route_table" "internet_route_worker" {
  provider = aws.region_worker
  vpc_id   = aws_vpc.vpc_master_worker.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_worker.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  }
  //lifecycle is added to prevent RT resource containing data from changing during a terraform creeate or update  
  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "worker-region-priv-RT"
  }
}

// Resource #13
// Overwrite default route table of worker VPC with new RT entries 
resource "aws_main_route_table_association" "set_worker_default_rt_assoc" {
  provider       = aws.region_worker
  vpc_id         = aws_vpc.vpc_master_worker.id
  route_table_id = aws_route_table.internet_route_worker.id
}
