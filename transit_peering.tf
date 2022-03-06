# ---------------------------------------------------------------------------------------------------------------------
# Aviatrix Transit Gateway Transit Peering
# ---------------------------------------------------------------------------------------------------------------------

resource "aviatrix_transit_gateway_peering" "ss_prd_peering" {
  transit_gateway_name1           = aviatrix_transit_gateway.ss_gw.gw_name
  transit_gateway_name2           = aviatrix_transit_gateway.prd_gw.gw_name
  gateway1_excluded_network_cidrs = ["0.0.0.0/0"]
  gateway2_excluded_network_cidrs = ["0.0.0.0/0"]
}