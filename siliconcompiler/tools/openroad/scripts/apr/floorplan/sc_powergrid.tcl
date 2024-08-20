
###########################
# Power Network
###########################

if { $openroad_pdn_enable == "true" && \
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
