###############################
# Setup timing derating
###############################

set sc_early_timing_derate [lindex [sc_cfg_tool_task_get {var} sta_early_timing_derate] 0]
if { $sc_early_timing_derate != 0.0 } {
    set_timing_derate -early $sc_early_timing_derate
}

set sc_late_timing_derate [lindex [sc_cfg_tool_task_get {var} sta_late_timing_derate] 0]
if { $sc_late_timing_derate != 0.0 } {
    set_timing_derate -late $sc_late_timing_derate
}
