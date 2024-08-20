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
# Global Placement and Refinement of Pin Placement
#######################

if { [sc_design_has_placeable_ios] } {
  #######################
  # Global Placement (without considering IO placements)
  #######################

  if { [lindex [sc_cfg_tool_task_get {var} gpl_enable_skip_io] 0] } {
    utl::info FLW 1 "Performing global placement without considering IO"
    sc_global_placement -skip_io
  }

  ###########################
  # Refine Automatic Pin Placement
  ###########################

  if { ![sc_has_unplaced_instances] } {
    sc_pin_placement
  } else {
    utl::info FLW 1 "Skipping pin placements refinement due to unplaced instances"
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
