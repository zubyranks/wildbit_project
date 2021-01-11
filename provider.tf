// Specify who carries out interraction with AWS APIs in the master region
// the provider pegs a resource to a specific provider
provider "aws" {
  profile = var.profile
  region  = var.region_master
  alias   = "region_master"
}

// Specify who carries out interraction with AWS APIs in the worker region
// the provider pegs a resource to a specific provider
provider "aws" {
  profile = var.profile
  region  = var.region_worker
  alias   = "region_worker"
}

