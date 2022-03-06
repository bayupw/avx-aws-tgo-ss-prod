module "onprem" {
  source          = "github.com/gleyfer/aviatrix-demo-onprem-aws"
  hostname        = "on-prem"
  tunnel_proto    = "IPsec"
  network_cidr    = var.vpc_cidr.on_prem_vpc
  public_subnets  = [cidrsubnet(var.vpc_cidr.on_prem_vpc, 1, 0)]
  private_subnets = [cidrsubnet(var.vpc_cidr.on_prem_vpc, 1, 1)]
  #advertised_prefixes = ["10.20.0.0/16", "10.30.0.0/16"]
  instance_type  = "t3.medium"
  public_conns   = ["ss-gw:65520:1"]
  csr_bgp_as_num = "65501"
  create_client  = true
  key_name       = var.key_name
  depends_on = [aviatrix_transit_gateway.ss_gw, aviatrix_vpc.ss_transit_vpc]
}