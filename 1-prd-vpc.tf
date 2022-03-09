# ---------------------------------------------------------------------------------------------------------------------
# prd VPCs
# ---------------------------------------------------------------------------------------------------------------------

# prd banking vpc
module "prd_banking_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "prd-banking"
  cidr = var.vpc_cidr.prd_banking_vpc

  azs             = ["${var.aws_region}a"]
  private_subnets = [cidrsubnet(var.vpc_cidr.prd_banking_vpc, 1, 1)]
  public_subnets  = [cidrsubnet(var.vpc_cidr.prd_banking_vpc, 1, 0)]
  enable_ipv6     = false
}

# prd it service vpc
module "prd_it_service_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "prd-it-service"
  cidr = var.vpc_cidr.prd_it_service_vpc

  azs             = ["${var.aws_region}a"]
  private_subnets = [cidrsubnet(var.vpc_cidr.prd_it_service_vpc, 1, 1)]
  public_subnets  = [cidrsubnet(var.vpc_cidr.prd_it_service_vpc, 1, 0)]
  enable_ipv6     = false
}

# prd-transit TGW - banking attachment
resource "aviatrix_aws_tgw_vpc_attachment" "prd_banking_tgw_attachment" {
  tgw_name             = aviatrix_aws_tgw.prd_tgw.tgw_name
  region               = var.aws_region
  security_domain_name = "Default_Domain"
  vpc_account_name     = var.aws_account
  vpc_id               = module.prd_banking_vpc.vpc_id
  depends_on           = [aviatrix_aws_tgw_security_domain.prd_default_domains]

  # ignore changes to allow migration
  lifecycle {
    ignore_changes = all
  }
}

# prd-transit TGW - it-service attachment
resource "aviatrix_aws_tgw_vpc_attachment" "prd_it_service_tgw_attachment" {
  tgw_name             = aviatrix_aws_tgw.prd_tgw.tgw_name
  region               = var.aws_region
  security_domain_name = "Shared_Service_Domain"
  vpc_account_name     = var.aws_account
  vpc_id               = module.prd_it_service.vpc_id
  depends_on           = [aviatrix_aws_tgw_security_domain.prd_default_domains]

  # ignore changes to allow migration
  lifecycle {
    ignore_changes = all
  }
}