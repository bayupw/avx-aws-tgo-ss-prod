# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix AWS Security VPC | ss-firenet
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_vpc" "ss_firenet_vpc" {
  cloud_type           = 1
  account_name         = var.aws_account
  region               = var.aws_region
  name                 = "ss-firenet"
  cidr                 = var.vpc_cidr.ss_firenet_vpc
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Firenet Gateway | ss-fw-gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_transit_gateway" "ss_fw_gw" {
  cloud_type   = 1
  account_name = var.aws_account
  gw_name      = "ss-fw-gw"
  vpc_id       = aviatrix_vpc.ss_firenet_vpc.vpc_id
  vpc_reg      = var.aws_region
  gw_size      = "c5.xlarge"
  subnet       = aviatrix_vpc.ss_firenet_vpc.public_subnets[0].cidr
  #ha_subnet                = aviatrix_vpc.ss_transit_vpc.public_subnets[1].cidr
  #ha_gw_size               = "t2.micro"
  enable_hybrid_connection = true
  connected_transit        = true
  single_az_ha             = false
  enable_active_mesh       = true
  enable_firenet           = true

  tags = {
    Organization = "Shared Services"
  }

  depends_on = [aviatrix_transit_gateway.ss_fw_gw, aviatrix_aws_tgw_security_domain_connection.ss_connections, aviatrix_aws_tgw_transit_gateway_attachment.ss_tgw_to_ss_gw_attachment]
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Firenet Gateway | ss-fw-gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_aws_tgw_vpc_attachment" "ss_firenet_tgw_attachment" {
  tgw_name             = aviatrix_aws_tgw.ss_tgw.tgw_name
  region               = var.aws_region
  security_domain_name = aviatrix_aws_tgw_security_domain.ss_firewall_domain.name
  vpc_account_name     = var.aws_account
  vpc_id               = aviatrix_vpc.ss_firenet_vpc.vpc_id
  depends_on           = [aviatrix_transit_gateway.ss_fw_gw]
}

# ---------------------------------------------------------------------------------------------------------------------
# Launch Firewall
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_firewall_instance" "ss_ew_fw_instance" {
  vpc_id          = aviatrix_vpc.ss_firenet_vpc.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.ss_fw_gw.gw_name
  firewall_name   = "ss-ew-fg-instance-1"
  firewall_image  = "Fortinet FortiGate Next-Generation Firewall"
  firewall_size   = "t2.small"
  egress_subnet   = aviatrix_vpc.ss_firenet_vpc.subnets[1].cidr
  #iam_role              = module.fortigate_bootstrap.aws_iam_role.name
  #bootstrap_bucket_name = module.fortigate_bootstrap.aws_s3_bucket.bucket
  user_data  = local.init_conf
  depends_on = [aviatrix_transit_gateway.ss_fw_gw]
}

# Associate an Aviatrix FireNet Gateway with a Firewall Instance
resource "aviatrix_firewall_instance_association" "ss_ew_fw_instance_assoc" {
  vpc_id          = aviatrix_firewall_instance.ss_ew_fw_instance.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.ss_fw_gw.gw_name
  instance_id     = aviatrix_firewall_instance.ss_ew_fw_instance.instance_id
  firewall_name   = aviatrix_firewall_instance.ss_ew_fw_instance.firewall_name
  lan_interface   = aviatrix_firewall_instance.ss_ew_fw_instance.lan_interface
  #management_interface = aviatrix_firewall_instance.ss_ew_fw_instance.management_interface
  egress_interface = aviatrix_firewall_instance.ss_ew_fw_instance.egress_interface
  attached         = true
}

# Create an Aviatrix FireNet
resource "aviatrix_firenet" "ss_firenet" {
  vpc_id                               = aviatrix_firewall_instance.ss_ew_fw_instance.vpc_id
  inspection_enabled                   = true
  egress_enabled                       = false
  keep_alive_via_lan_interface_enabled = false
  manage_firewall_instance_association = false
  depends_on                           = [aviatrix_firewall_instance_association.ss_ew_fw_instance_assoc]
}