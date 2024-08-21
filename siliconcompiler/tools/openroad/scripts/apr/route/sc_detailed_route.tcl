###############################
# Reading SC Schema
###############################

source ./sc_manifest.tcl > /dev/null

##############################
# Source OpenROAD driver
###############################

source "[sc_cfg_tool_task_get refdir]/utils/template/sc_driver.tcl"

##############################
# Source prescript scripts
###############################

utl::push_metrics_stage "sc__prestep__{}"
foreach sc_pre_script [sc_cfg_tool_task_get prescript] {
    puts "Sourcing prescript: ${sc_pre_script}"
    source -echo $sc_pre_script
}
utl::pop_metrics_stage

###########################
# Setup task metrics collection
###########################

utl::push_metrics_stage "sc__step__{}"

###########################
# Detailed route
###########################

set openroad_drt_arguments []
if { [lindex [sc_cfg_tool_task_get {var} drt_disable_via_gen] 0] == "true" } {
  lappend openroad_drt_arguments "-disable_via_gen"
}
set drt_process_node [lindex [sc_cfg_tool_task_get {var} drt_process_node] 0]
if { $drt_process_node != "" } {
  lappend openroad_drt_arguments "-db_process_node" $drt_process_node
}
set drt_via_in_pin_bottom_layer \
  [sc_get_layer_name [lindex [sc_cfg_tool_task_get {var} drt_via_in_pin_bottom_layer] 0]]
if { $drt_via_in_pin_bottom_layer != "" } {
  lappend openroad_drt_arguments "-via_in_pin_bottom_layer" $drt_via_in_pin_bottom_layer
}
set drt_via_in_pin_top_layer \
  [sc_get_layer_name [lindex [sc_cfg_tool_task_get {var} drt_via_in_pin_top_layer] 0]]
if { $drt_via_in_pin_top_layer != "" } {
  lappend openroad_drt_arguments "-via_in_pin_top_layer" $drt_via_in_pin_top_layer
}
set drt_repair_pdn_vias \
  [sc_get_layer_name [lindex [sc_cfg_tool_task_get {var} drt_repair_pdn_vias] 0]]
if { $drt_repair_pdn_vias != "" } {
  lappend openroad_drt_arguments "-repair_pdn_vias" $drt_repair_pdn_vias
}

set sc_minmetal [sc_get_layer_name [sc_cfg_get pdk $sc_pdk minlayer $sc_stackup]]
set sc_maxmetal [sc_get_layer_name [sc_cfg_get pdk $sc_pdk maxlayer $sc_stackup]]

detailed_route -save_guide_updates \
  -output_drc "reports/${sc_design}_drc.rpt" \
  -output_maze "reports/${sc_design}_maze.log" \
  -bottom_routing_layer $sc_minmetal \
  -top_routing_layer $sc_maxmetal \
  -verbose 1 \
  {*}$openroad_drt_arguments

# estimate for metrics
estimate_parasitics -global_routing

###########################
# End task metrics collection
###########################

utl::pop_metrics_stage

##############################
# Source postscripts scripts
###############################

utl::push_metrics_stage "sc__poststep__{}"
if { [sc_cfg_tool_task_exists postscript] } {
  foreach sc_post_script [sc_cfg_tool_task_get postscript] {
    puts "Sourcing post script: ${sc_post_script}"
    source -echo $sc_post_script
  }
}
utl::pop_metrics_stage

###############################
# Write Design Data
###############################

utl::push_metrics_stage "sc__write__{}"
source "${sc_refdir}/utils/write_data.tcl"
utl::pop_metrics_stage

###############################
# Reporting
###############################

utl::push_metrics_stage "sc__metric__{}"
source "${sc_refdir}/utils/metrics.tcl"
utl::pop_metrics_stage
