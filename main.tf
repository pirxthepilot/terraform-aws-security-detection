# Provider details
provider "aws" {
  profile = "default"
  region  = var.region
}

# Spin up the test VPC whose default security
# group will be used for this deployment
module "test_vpc" {
  source = "./modules/test_vpc"

  cidr_block = "10.234.0.0/24"
}

# Enable Cloudtrail (includes S3 bucket setup)
module "cloudtrail" {
  source = "./modules/cloudtrail"
}
