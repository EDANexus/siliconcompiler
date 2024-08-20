###############################
# Setup debugging if requested
###############################

if { [llength [sc_cfg_tool_task_get {var} debug_level]] > 0 } {
    foreach debug [sc_cfg_tool_task_get {var} debug_level] {
        set debug_setting [split $debug " "]
        set debug_tool [lindex $debug_setting 0]
        set debug_category [lindex $debug_setting 1]
        set debug_level [lindex $debug_setting 2]
        utl::info FLW 1 "Setting debugging for $debug_tool/$debug_category/$debug_level"
        set_debug_level $debug_tool $debug_category $debug_level
    }
}

###############################
# Suppress messages if requested
###############################

foreach msg [sc_cfg_tool_task_get warningoff] {
    set or_msg [split $msg "-"]
    if { [llength $or_msg] != 2 } {
        utl::warn FLW 1 "$msg is not a valid message id"
    } else {
        set or_tool [lindex $or_msg 0]
        set or_msg_id [expr { int([lindex $or_msg 1]) }]
        utl::info FLW 1 "Suppressing $msg messages"
        suppress_message $or_tool $or_msg_id
    }
}
