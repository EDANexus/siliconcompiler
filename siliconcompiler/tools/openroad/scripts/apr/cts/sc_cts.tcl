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

#######################################
# Clock tree synthesis
# (skip if no clocks defined)
#######################################

if { [llength [all_clocks]] > 0 } {

  # Clone clock tree inverters next to register loads
  # so cts does not try to buffer the inverted clocks.
  repair_clock_inverters

  set sc_cts_arguments []
  if { [lindex [sc_cfg_tool_task_get {var} cts_balance_levels] 0] == "true" } {
    lappend sc_cts_arguments "-balance_levels"
  }
  if { [lindex [sc_cfg_tool_task_get {var} cts_obstruction_aware] 0] == "true" } {
    lappend sc_cts_arguments "-obstruction_aware"
  }

  set sc_clkbuf [lindex [sc_cfg_tool_task_get {var} cts_clock_buffer] 0]

  set cts_distance_between_buffers \
    [lindex [sc_cfg_tool_task_get {var} cts_distance_between_buffers] 0]
  set cts_cluster_diameter [lindex [sc_cfg_tool_task_get {var} cts_cluster_diameter] 0]
  set cts_cluster_size [lindex [sc_cfg_tool_task_get {var} cts_cluster_size] 0]

  clock_tree_synthesis -root_buf $sc_clkbuf -buf_list $sc_clkbuf \
    -sink_clustering_enable \
    -sink_clustering_size $cts_cluster_size \
    -sink_clustering_max_diameter $cts_cluster_diameter \
    -distance_between_buffers $cts_distance_between_buffers \
    {*}$sc_cts_arguments

  set_propagated_clock [all_clocks]

  estimate_parasitics -placement

  repair_clock_nets

  sc_detailed_placement

  estimate_parasitics -placement
}

global_connect

# estimate for metrics
estimate_parasitics -placement

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
