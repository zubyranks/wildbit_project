terraform {
  required_version = ">=0.14.3"
  backend "s3" {
    profile = "terraform"
    bucket  = "zubyranks-terraform"
    key     = "terraform_state_file"
    region  = "eu-central-1"
  }
}
