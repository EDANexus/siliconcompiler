
set repair_timing_args []
if { $openroad_rsz_skip_pin_swap == "true" } {
lappend repair_timing_args "-skip_pin_swap"
}
if { $openroad_rsz_skip_gate_cloning == "true" } {
lappend repair_timing_args "-skip_gate_cloning"
}

repair_timing -setup -verbose \
-setup_margin $openroad_rsz_setup_slack_margin \
-hold_margin $openroad_rsz_hold_slack_margin \
-repair_tns $openroad_rsz_repair_tns \
{*}$repair_timing_args

estimate_parasitics -placement
repair_timing -hold -verbose \
-setup_margin $openroad_rsz_setup_slack_margin \
-hold_margin $openroad_rsz_hold_slack_margin \
-repair_tns $openroad_rsz_repair_tns \
{*}$repair_timing_args

sc_detailed_placement

global_connect

# estimate for metrics
estimate_parasitics -placement
