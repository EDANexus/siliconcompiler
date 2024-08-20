##############################
# Schema adapter
###############################

set sc_step [sc_cfg_get arg step]
set sc_index [sc_cfg_get arg index]

set sc_flow [sc_cfg_get option flow]
set sc_task [sc_cfg_get flowgraph $sc_flow $sc_step $sc_index task]
set sc_tool [sc_cfg_get flowgraph $sc_flow $sc_step $sc_index tool]

set sc_refdir [sc_cfg_tool_task_get refdir]

###############################
# Set commonly used variables
###############################

# Design information
set sc_design [sc_cfg_get design]

# PDK information
set sc_pdk [sc_cfg_get option pdk]
set sc_stackup [sc_cfg_get option stackup]

# Library information
set sc_targetlibs [sc_get_asic_libraries logic]
set sc_mainlib [lindex $sc_targetlibs 0]
set sc_macrolibs [sc_get_asic_libraries macro]

##############################
# Source setup scripts
###############################

# Helper functions
source "${sc_refdir}/utils/procs.tcl"

source "${sc_refdir}/utils/setup/logging.tcl"
source "${sc_refdir}/utils/load_data.tcl"
source "${sc_refdir}/utils/setup/timing.tcl"
source "${sc_refdir}/utils/setup/parasitics.tcl"
source "${sc_refdir}/utils/setup/routing.tcl"

##############################
# Initialize openroad
###############################

set_thread_count [sc_cfg_tool_task_get threads]

report_units_metric
set openroad_dont_touch {}
if { [sc_cfg_tool_task_exists {var} dont_touch] } {
  set openroad_dont_touch [sc_cfg_tool_task_get {var} dont_touch]
}
if { [llength $openroad_dont_touch] > 0 } {
    # set don't touch list
    set_dont_touch $openroad_dont_touch
}
