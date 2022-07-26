provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

resource "aws_eip" "nat" {
  count = 3
  vpc = true
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = "${var.environment}-anchorplatform-fargatedemo-vpc"
  cidr                 = "10.100.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.100.10.0/26", "10.100.10.64/26", "10.100.10.128/26"]
  public_subnets       = ["10.100.12.0/26", "10.100.12.64/26", "10.100.12.128/26"]
  enable_nat_gateway   = true
  single_nat_gateway   = false
  reuse_nat_ips        = true
  external_nat_ip_ids = "${aws_eip.nat.*.id}" 
  enable_dns_hostnames = true
}
