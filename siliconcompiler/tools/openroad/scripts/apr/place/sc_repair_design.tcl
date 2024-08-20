
#######################
# Repair Design
#######################

estimate_parasitics -placement

if { $openroad_rsz_buffer_inputs == "true" } {
  buffer_ports -inputs
}
if { $openroad_rsz_buffer_outputs == "true" } {
  buffer_ports -outputs
}

set repair_design_args []
if { $openroad_rsz_cap_margin != "false" } {
  lappend repair_design_args "-cap_margin" $openroad_rsz_cap_margin
}
if { $openroad_rsz_slew_margin != "false" } {
  lappend repair_design_args "-slew_margin" $openroad_rsz_slew_margin
}
repair_design -verbose {*}$repair_design_args

#######################
# TIE FANOUT
#######################

foreach tie_type "high low" {
  if { [has_tie_cell $tie_type] } {
    repair_tie_fanout -separation $openroad_ifp_tie_separation [get_tie_cell $tie_type]
  }
}
