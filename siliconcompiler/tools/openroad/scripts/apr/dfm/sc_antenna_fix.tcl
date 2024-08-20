
######################
# Report and Repair Antennas
######################

estimate_parasitics -global_routing
if { $openroad_ant_check == "true" && \
     [check_antennas -report_file "reports/${sc_design}_antenna.rpt"] != 0 } {
  if { $openroad_ant_repair == "true" && \
       [llength [sc_cfg_get library $sc_mainlib asic cells antenna]] != 0 } {
    set sc_antenna [lindex [sc_cfg_get library $sc_mainlib asic cells antenna] 0]

    # Remove filler cells before attempting to repair antennas
    remove_fillers

    repair_antenna $sc_antenna \
      -iterations $openroad_ant_iterations \
      -ratio_margin $openroad_ant_margin

    # Add filler cells back
    insert_fillers

    # Check antennas again to get final report
    check_antennas -report_file "reports/${sc_design}_antenna_post_repair.rpt"
  }
}
