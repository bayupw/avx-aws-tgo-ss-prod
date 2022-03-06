# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix AWS Security VPC | prd-firenet
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_vpc" "prd_firenet_vpc" {
  cloud_type           = 1
  account_name         = var.aws_account
  region               = var.aws_region
  name                 = "prd-firenet"
  cidr                 = var.vpc_cidr.prd_firenet_vpc
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Firenet Gateway | prd-fw-gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_transit_gateway" "prd_fw_gw" {
  cloud_type   = 1
  account_name = var.aws_account
  gw_name      = "prd-fw-gw"
  vpc_id       = aviatrix_vpc.prd_firenet_vpc.vpc_id
  vpc_reg      = var.aws_region
  gw_size      = "c5.xlarge"
  subnet       = aviatrix_vpc.prd_firenet_vpc.public_subnets[0].cidr
  #ha_subnet                = aviatrix_vpc.dev_transit_vpc.public_subnets[1].cidr
  #ha_gw_size               = "t2.micro"
  enable_hybrid_connection = true
  connected_transit        = true
  single_az_ha             = false
  enable_active_mesh       = true
  enable_firenet           = true

  tags = {
    Organization = "Production"
  }

  depends_on = [aviatrix_vpc.prd_firenet_vpc]
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Firenet Gateway | prd-fw-gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_aws_tgw_vpc_attachment" "firenet_tgw_attachment" {
  tgw_name             = aviatrix_aws_tgw.prd_tgw.tgw_name
  region               = var.aws_region
  security_domain_name = aviatrix_aws_tgw_security_domain.prd_firewall_domain.name
  vpc_account_name     = var.aws_account
  vpc_id               = aviatrix_vpc.prd_firenet_vpc.vpc_id
  depends_on           = [aviatrix_transit_gateway.prd_fw_gw]
}

# ---------------------------------------------------------------------------------------------------------------------
# Launch Firewall
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_firewall_instance" "prd_ew_fw_instance" {
  vpc_id          = aviatrix_vpc.prd_firenet_vpc.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.prd_fw_gw.gw_name
  firewall_name   = "prd-ew-fg-instance-1"
  firewall_image  = "Fortinet FortiGate Next-Generation Firewall"
  firewall_size   = "t2.small"
  egress_subnet   = aviatrix_vpc.prd_firenet_vpc.subnets[1].cidr
  #iam_role              = module.fortigate_bootstrap.aws_iam_role.name
  #bootstrap_bucket_name = module.fortigate_bootstrap.aws_s3_bucket.bucket
  user_data  = local.init_conf
  depends_on = [aviatrix_transit_gateway.prd_fw_gw]
}

# Associate an Aviatrix FireNet Gateway with a Firewall Instance
resource "aviatrix_firewall_instance_association" "prd_ew_fw_instance_assoc" {
  vpc_id          = aviatrix_firewall_instance.prd_ew_fw_instance.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.prd_fw_gw.gw_name
  instance_id     = aviatrix_firewall_instance.prd_ew_fw_instance.instance_id
  firewall_name   = aviatrix_firewall_instance.prd_ew_fw_instance.firewall_name
  lan_interface   = aviatrix_firewall_instance.prd_ew_fw_instance.lan_interface
  #management_interface = aviatrix_firewall_instance.dev_ew_fw_instance.management_interface
  egress_interface = aviatrix_firewall_instance.prd_ew_fw_instance.egress_interface
  attached         = true
}

# Create an Aviatrix FireNet
resource "aviatrix_firenet" "prd_firenet" {
  vpc_id                               = aviatrix_firewall_instance.prd_ew_fw_instance.vpc_id
  inspection_enabled                   = true
  egress_enabled                       = false
  keep_alive_via_lan_interface_enabled = false
  manage_firewall_instance_association = false
  depends_on                           = [aviatrix_firewall_instance_association.prd_ew_fw_instance_assoc]
}