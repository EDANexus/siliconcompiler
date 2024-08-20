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
# Check if macros are unplaced
###########################

if { [sc_design_has_unplaced_macros] } {
  utl::error FLW 1 "Design contains unplaced macros."
}

###########################
# Insert tie cells
###########################

foreach tie_type "high low" {
  if { [has_tie_cell $tie_type] } {
    insert_tiecells [get_tie_cell $tie_type]
  }
}
global_connect

###########################
# Tap cells
###########################

if { [sc_cfg_tool_task_exists {file} ifp_tapcell] } {
  set tapcell_file [lindex [sc_cfg_tool_task_get {file} ifp_tapcell] 0]
  puts "Sourcing tapcell file: ${tapcell_file}"
  source $tapcell_file
  global_connect
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
