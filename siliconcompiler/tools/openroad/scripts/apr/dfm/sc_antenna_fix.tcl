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

######################
# Report and repair antenna violations
######################

estimate_parasitics -global_routing
if { [lindex [sc_cfg_tool_task_get {var} ant_check] 0] == "true" && \
     [check_antennas -report_file "reports/${sc_design}_antenna.rpt"] != 0 } {
  if { [lindex [sc_cfg_tool_task_get {var} ant_repair] 0] == "true" && \
       [llength [sc_cfg_get library $sc_mainlib asic cells antenna]] != 0 } {
    set sc_antenna [lindex [sc_cfg_get library $sc_mainlib asic cells antenna] 0]

    # Remove filler cells before attempting to repair antennas
    remove_fillers

    repair_antenna $sc_antenna \
      -iterations $openroad_ant_iterations \
      -ratio_margin $openroad_ant_margin

    # Add filler cells back
    sc_insert_fillers

    # Check antennas again to get final report
    check_antennas -report_file "reports/${sc_design}_antenna_post_repair.rpt"
  }
}

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
