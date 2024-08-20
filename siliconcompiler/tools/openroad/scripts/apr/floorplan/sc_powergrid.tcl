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
# Power Network
###########################

if { [lindex [sc_cfg_tool_task_get {var} pdn_enable] 0] == "true" && \
     [sc_cfg_tool_task_exists {file} pdn_config] && \
     [llength [sc_cfg_tool_task_get {file} pdn_config]] > 0 } {
  set pdn_files []
  foreach pdnconfig [sc_cfg_tool_task_get {file} pdn_config] {
    if { [lsearch -exact $pdn_files $pdnconfig] != -1 } {
      continue
    }
    puts "Sourcing PDNGEN configuration: ${pdnconfig}"
    source $pdnconfig

    lappend pdn_files $pdnconfig
  }
  pdngen -failed_via_report "reports/${sc_design}_pdngen_failed_vias.rpt"
} else {
  utl::warn FLW 1 "No power grid inserted"
}

###########################
# Check Power Network
###########################

foreach net [sc_supply_nets] {
  if { ![[[ord::get_db_block] findNet $net] isSpecial] } {
    utl::warn FLW 1 "$net_name is marked as a supply net, but is not marked as a special net"
  }
}

foreach net [sc_psm_check_nets] {
  puts "Check supply net: $net"
  check_power_grid \
    -floorplanning \
    -error_file "reports/power_grid_${net}.rpt" \
    -net $net
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
