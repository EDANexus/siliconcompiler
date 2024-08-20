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
# Perform macro placement
###########################

# Need to check if we have any macros before performing macro placement,
# since we get an error otherwise.
if { [sc_design_has_unplaced_macros] } {
  if { $openroad_rtlmp_enable == "true" } {
    set halo_max [expr { max([lindex $openroad_mpl_macro_place_halo 0], \
                             [lindex $openroad_mpl_macro_place_halo 1]) }]

    set rtlmp_args []
    if { $openroad_rtlmp_min_instances != "" } {
      lappend rtlmp_args -min_num_inst $openroad_rtlmp_min_instances
    }
    if { $openroad_rtlmp_max_instances != "" } {
      lappend rtlmp_args -max_num_inst $openroad_rtlmp_max_instances
    }
    if { $openroad_rtlmp_min_macros != "" } {
      lappend rtlmp_args -min_num_macro $openroad_rtlmp_min_macros
    }
    if { $openroad_rtlmp_max_macros != "" } {
      lappend rtlmp_args -max_num_macro $openroad_rtlmp_max_macros
    }

    rtl_macro_placer -report_directory reports/rtlmp \
      -halo_width $halo_max \
      {*}$rtlmp_args
  } else {
    ###########################
    # TDMS Global Placement
    ###########################

    sc_global_placement -disable_routability_driven

    ###########################
    # Macro placement
    ###########################

    macro_placement -halo $openroad_mpl_macro_place_halo \
      -channel $openroad_mpl_macro_place_channel

    # Note: some platforms set a "macro blockage halo" at this point, but the
    # technologies we support do not, so we don't include that step for now.
  }
}
if { [sc_design_has_unplaced_macros] } {
  utl::error FLW 1 "Design contains unplaced macros."
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
