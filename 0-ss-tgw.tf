# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix AWS VPC | ss-transit
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_vpc" "ss_transit_vpc" {
  cloud_type           = 1
  account_name         = var.aws_account
  region               = var.aws_region
  name                 = "ss-transit"
  cidr                 = var.vpc_cidr.ss_transit_vpc
  aviatrix_transit_vpc = true
  aviatrix_firenet_vpc = false
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Gateway | ss-gw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_transit_gateway" "ss_gw" {
  cloud_type   = 1
  account_name = var.aws_account
  gw_name      = "ss-gw"
  vpc_id       = aviatrix_vpc.ss_transit_vpc.vpc_id
  vpc_reg      = var.aws_region
  gw_size      = "t2.micro"
  subnet       = aviatrix_vpc.ss_transit_vpc.public_subnets[0].cidr
  #ha_subnet                = aviatrix_vpc.ss_transit_vpc.public_subnets[1].cidr
  #ha_gw_size               = "t2.micro"
  enable_hybrid_connection      = true
  connected_transit             = true
  single_az_ha                  = false
  local_as_number               = "65520"
  enable_active_mesh            = true
  enable_learned_cidrs_approval = true
  #approved_learned_cidrs = [cidrsubnet(var.vpc_cidr.on_prem_vpc, 1, 0),cidrsubnet(var.vpc_cidr.on_prem_vpc, 1, 1)]

  tags = {
    Organization = "Shared-Services"
  }

  # ignore changes to allow migration
  lifecycle {
    ignore_changes = all
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Managed AWS TGW | ss-tgw
# ---------------------------------------------------------------------------------------------------------------------
resource "aviatrix_aws_tgw" "ss_tgw" {
  account_name                      = var.aws_account
  aws_side_as_number                = "65500"
  manage_vpc_attachment             = false
  manage_transit_gateway_attachment = false
  manage_security_domain            = false
  region                            = var.aws_region
  tgw_name                          = "ss-tgw"
}

# Create Security Domains based on var.tgw_domains
resource "aviatrix_aws_tgw_security_domain" "ss_default_domains" {
  for_each   = toset(var.tgw_domains)
  name       = each.value
  tgw_name   = aviatrix_aws_tgw.ss_tgw.tgw_name
  depends_on = [aviatrix_aws_tgw.ss_tgw]
}

# Create Firewall Security Domain
resource "aviatrix_aws_tgw_security_domain" "ss_firewall_domain" {
  name              = "Firewall"
  tgw_name          = aviatrix_aws_tgw.ss_tgw.tgw_name
  aviatrix_firewall = true
  depends_on        = [aviatrix_aws_tgw_security_domain.ss_default_domains]
}

resource "aviatrix_aws_tgw_security_domain_connection" "ss_connections" {
  for_each     = local.connections_map
  tgw_name     = aviatrix_aws_tgw.ss_tgw.tgw_name
  domain_name1 = each.value.domain1
  domain_name2 = each.value.domain2
  depends_on   = [aviatrix_aws_tgw_security_domain.ss_default_domains, aviatrix_aws_tgw_security_domain.ss_firewall_domain]
}

# ss-tgw to ss-gw attachment
resource "aviatrix_aws_tgw_transit_gateway_attachment" "ss_tgw_to_ss_gw_attachment" {
  tgw_name             = aviatrix_aws_tgw.ss_tgw.tgw_name
  region               = var.aws_region
  vpc_account_name     = var.aws_account
  vpc_id               = aviatrix_vpc.ss_transit_vpc.vpc_id
  transit_gateway_name = aviatrix_transit_gateway.ss_gw.gw_name

  depends_on = [aviatrix_transit_gateway.ss_gw, aviatrix_aws_tgw.ss_tgw, aviatrix_aws_tgw_security_domain_connection.ss_connections]
}