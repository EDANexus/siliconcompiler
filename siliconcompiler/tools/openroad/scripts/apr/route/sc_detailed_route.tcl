
set openroad_drt_arguments []
if { $openroad_drt_disable_via_gen == "true" } {
  lappend openroad_drt_arguments "-disable_via_gen"
}
if { $openroad_drt_process_node != "" } {
  lappend openroad_drt_arguments "-db_process_node" $openroad_drt_process_node
}
if { $openroad_drt_via_in_pin_bottom_layer != "" } {
  lappend openroad_drt_arguments "-via_in_pin_bottom_layer" $openroad_drt_via_in_pin_bottom_layer
}
if { $openroad_drt_via_in_pin_top_layer != "" } {
  lappend openroad_drt_arguments "-via_in_pin_top_layer" $openroad_drt_via_in_pin_top_layer
}
if { $openroad_drt_repair_pdn_vias != "" } {
  lappend openroad_drt_arguments "-repair_pdn_vias" $openroad_drt_repair_pdn_vias
}

detailed_route -save_guide_updates \
  -output_drc "reports/${sc_design}_drc.rpt" \
  -output_maze "reports/${sc_design}_maze.log" \
  -bottom_routing_layer $sc_minmetal \
  -top_routing_layer $sc_maxmetal \
  -verbose 1 \
  {*}$openroad_drt_arguments
