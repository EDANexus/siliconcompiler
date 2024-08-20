###############################
# Load parasitic information
###############################

foreach sc_parasitic_file [sc_cfg_tool_task_get {file} parasitics] {
    source $sc_parasitic_file
}

###############################
# Setup parasitic estimation
###############################

set sc_rc_signal [sc_get_layer_name [lindex [sc_cfg_get pdk $sc_pdk {var} $sc_tool rclayer_signal $sc_stackup] 0]]
set_wire_rc -signal -layer $sc_rc_signal
utl::info FLW 1 "Using $sc_rc_signal for signal parasitics estimation"

set sc_rc_clk [sc_get_layer_name [lindex [sc_cfg_get pdk $sc_pdk {var} $sc_tool rclayer_clock $sc_stackup] 0]]
set_wire_rc -clock -layer $sc_rc_clk
utl::info FLW 1 "Using $sc_rc_clk for clock parasitics estimation"
