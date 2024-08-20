
#######################
# DETAILED PLACEMENT
#######################

sc_detailed_placement

if { $openroad_dpo_enable == "true" } {
  improve_placement -max_displacement $openroad_dpo_max_displacement

  # Do another detailed placement in case DPO leaves violations behind
  sc_detailed_placement
}

optimize_mirroring

check_placement -verbose

global_connect

# estimate for metrics
estimate_parasitics -placement
