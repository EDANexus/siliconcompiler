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

#######################
# Repair design
#######################

estimate_parasitics -placement

if { [lindex [sc_cfg_tool_task_get {var} rsz_buffer_inputs] 0] == "true" } {
  buffer_ports -inputs
}
if { [lindex [sc_cfg_tool_task_get {var} rsz_buffer_outputs] 0] == "true" } {
  buffer_ports -outputs
}

set repair_design_args []

set rsz_cap_margin [lindex [sc_cfg_tool_task_get {var} rsz_cap_margin] 0]
if { $rsz_cap_margin != "false" } {
  lappend repair_design_args "-cap_margin" $rsz_cap_margin
}
set rsz_slew_margin [lindex [sc_cfg_tool_task_get {var} rsz_slew_margin] 0]
if { $rsz_slew_margin != "false" } {
  lappend repair_design_args "-slew_margin" $rsz_slew_margin
}

repair_design -verbose {*}$repair_design_args

#######################
# Tie-off cell insertion
#######################

set tie_separation [lindex [sc_cfg_tool_task_get {var} ifp_tie_separation] 0]
foreach tie_type "high low" {
  if { [has_tie_cell $tie_type] } {
    repair_tie_fanout -separation $tie_separation [get_tie_cell $tie_type]
  }
}

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
