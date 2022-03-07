# ---------------------------------------------------------------------------------------------------------------------
# CIDR
# ---------------------------------------------------------------------------------------------------------------------
# Subnetting
variable "vpc_cidr" {
  type = map(string)
  default = {
    prd_transit_vpc   = "172.19.44.0/23"
    ss_transit_vpc    = "172.19.142.0/23"
    stass_transit_vpc = "172.19.174.0/23"
    sta_transit_vpc   = "172.19.176.0/23"
    dev_transit_vpc   = "172.19.178.0/23"

    prd_firenet_vpc = "172.19.46.0/23"
    ss_firenet_vpc  = "172.19.144.0/23"
    dev_firenet_vpc = "172.19.180.0/23"

    prd_spoke1_vpc = "172.19.0.0/23"
    prd_spoke2_vpc = "172.19.2.0/23"

    ss_spoke1_vpc = "172.18.0.0/23"
    ss_spoke2_vpc = "172.18.2.0/23"

    stass_spoke1_vpc = "172.18.4.0/23"
    stass_spoke2_vpc = "172.18.6.0/23"

    sta_spoke1_vpc = "172.18.8.0/23"
    sta_spoke2_vpc = "172.18.10.0/23"

    dev_spoke1_vpc = "172.18.12.0/23"
    dev_spoke2_vpc = "172.18.14.0/23"

    on_prem_vpc = "192.168.0.0/23"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CSP Accounts
# ---------------------------------------------------------------------------------------------------------------------
variable "aws_account" {
  type        = string
  description = "AWS access account"
}

# ---------------------------------------------------------------------------------------------------------------------
# CSP Regions
# ---------------------------------------------------------------------------------------------------------------------
variable "aws_region" {
  type        = string
  default     = "ap-southeast-2"
  description = "AWS region"
}

# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit & Spoke Gateway
# ---------------------------------------------------------------------------------------------------------------------
variable "aws_instance_size" {
  type        = string
  default     = "t2.micro" #hpe "c5.xlarge"
  description = "AWS gateway instance size"
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS EC2
# ---------------------------------------------------------------------------------------------------------------------
variable "create_ec2" {
  type        = bool
  default     = false
  description = "Create EC2 instance"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "amzn2-ami-hvm*"
}

variable "key_name" {
  type        = string
  default     = null
  description = "Existing SSH public key name"
}

variable "fw_admin_password" {
  type        = string
  default     = "Aviatrix123#"
  description = "Firewall admin password"
}

variable "ingress_ip" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Ingress CIDR block for EC2 Security Group"
}

# ---------------------------------------------------------------------------------------------------------------------
# TGW
# ---------------------------------------------------------------------------------------------------------------------

variable "tgw_domains" {
  description = "Default Domain Name"
  default = [
    "Default_Domain",
    "Shared_Service_Domain",
    "Aviatrix_Edge_Domain"
  ]
}

locals {

  rfc1918             = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  ingress_cidr_blocks = concat(local.rfc1918, [var.ingress_ip])

  #Create connections based on var.tgw_domains
  connections = flatten([
    for domain in var.tgw_domains : [
      for connected_domain in slice(var.tgw_domains, index(var.tgw_domains, domain) + 1, length(var.tgw_domains)) : {
        domain1 = domain
        domain2 = connected_domain
      }
    ]
  ])

  #Create map to be used in for_each
  connections_map = {
    for connection in local.connections : "${connection.domain1}:${connection.domain2}" => connection
  }

  fw_domains = concat(var.tgw_domains, ["Firewall"])

  #Create connections based on local.fw_domains
  fw_connections = flatten([
    for domain in local.fw_domains : [
      for connected_domain in slice(local.fw_domains, index(local.fw_domains, domain) + 1, length(local.fw_domains)) : {
        domain1 = domain
        domain2 = connected_domain
      }
    ]
  ])

  #Create map to be used in for_each
  fw_connections_map = {
    for connection in local.fw_connections : "${connection.domain1}:${connection.domain2}" => connection
  }

  # Shared Services Fortigate Firewall bootstrap config
  ss_fw_init_conf = <<EOF
config system admin
    edit admin
        set password ${var.fw_admin_password}
end
config system global
    set hostname fg
    set timezone 04
end
config system interface
    edit port2
    set allowaccess ping https
end
config router static
    edit 1
        set dst 10.0.0.0 255.0.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.ss_fw_gw.lan_interface_cidr, 1)}
        set device port2
    next
    edit 2
        set dst 172.16.0.0 255.240.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.ss_fw_gw.lan_interface_cidr, 1)}
        set device port2
    next
    edit 3
        set dst 192.168.0.0 255.255.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.ss_fw_gw.lan_interface_cidr, 1)}
        set device port2
    next
end
config firewall policy
    edit 1
        set name allow-all-LAN-to-LAN
        set srcintf port2
        set dstintf port2
        set srcaddr all
        set dstaddr all
        set action accept
        set schedule always
        set service ALL
        set logtraffic all
        set logtraffic-start enable
    next
end
EOF

  # Production Fortigate Firewall bootstrap config
  prd_fw_init_conf = <<EOF
config system admin
    edit admin
        set password ${var.fw_admin_password}
end
config system global
    set hostname fg
    set timezone 04
end
config system interface
    edit port2
    set allowaccess ping https
end
config router static
    edit 1
        set dst 10.0.0.0 255.0.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.prd_fw_gw.lan_interface_cidr, 1)}
        set device port2
    next
    edit 2
        set dst 172.16.0.0 255.240.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.prd_fw_gw.lan_interface_cidr, 1)}
        set device port2
    next
    edit 3
        set dst 192.168.0.0 255.255.0.0
        set gateway ${cidrhost(aviatrix_transit_gateway.prd_fw_gw.lan_interface_cidr, 1)}
        set device port2
    next
end
config firewall policy
    edit 1
        set name allow-all-LAN-to-LAN
        set srcintf port2
        set dstintf port2
        set srcaddr all
        set dstaddr all
        set action accept
        set schedule always
        set service ALL
        set logtraffic all
        set logtraffic-start enable
    next
end
EOF
}