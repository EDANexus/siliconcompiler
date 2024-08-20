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

set_propagated_clock [all_clocks]

set repair_timing_args []
if { [lindex [sc_cfg_tool_task_get {var} rsz_skip_pin_swap] 0] == "true" } {
    lappend repair_timing_args "-skip_pin_swap"
}
if { [lindex [sc_cfg_tool_task_get {var} rsz_skip_gate_cloning] 0] == "true" } {
    lappend repair_timing_args "-skip_gate_cloning"
}

set rsz_setup_slack_margin [lindex [sc_cfg_tool_task_get {var} rsz_setup_slack_margin] 0]
set rsz_hold_slack_margin [lindex [sc_cfg_tool_task_get {var} rsz_hold_slack_margin] 0]
set rsz_repair_tns [lindex [sc_cfg_tool_task_get {var} rsz_repair_tns] 0]

repair_timing -setup -verbose \
    -setup_margin $rsz_setup_slack_margin \
    -hold_margin $rsz_hold_slack_margin \
    -repair_tns $rsz_repair_tns \
    {*}$repair_timing_args

estimate_parasitics -placement
repair_timing -hold -verbose \
    -setup_margin $rsz_setup_slack_margin \
    -hold_margin $rsz_hold_slack_margin \
    -repair_tns $rsz_repair_tns \
    {*}$repair_timing_args

sc_detailed_placement

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
