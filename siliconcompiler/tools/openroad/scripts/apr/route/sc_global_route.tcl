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
# Global route
###########################

set sc_grt_arguments []
if { [lindex [sc_cfg_tool_task_get {var} grt_allow_congestion] 0] == "true" } {
  lappend sc_grt_arguments "-allow_congestion"
}
if { [lindex [sc_cfg_tool_task_get {var} grt_allow_overflow] 0] == "true" } {
  lappend sc_grt_arguments "-allow_overflow"
}

global_route -guide_file "./route.guide" \
  -congestion_iterations [lindex [sc_cfg_tool_task_get {var} grt_overflow_iter] 0] \
  -congestion_report_file "reports/${sc_design}_congestion.rpt" \
  -verbose \
  {*}$sc_grt_arguments

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
