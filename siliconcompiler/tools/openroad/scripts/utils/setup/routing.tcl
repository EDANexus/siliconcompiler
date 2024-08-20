######################
# Setup global route options
######################

set has_routing_tracks 0

# Adjust routing track density
foreach layer [[ord::get_db_tech] getLayers] {
    if { [ $layer getRoutingLevel ] == 0 } {
        continue
    }

    if { [ord::db_layer_has_hor_tracks $layer] || [ord::db_layer_has_ver_tracks $layer] } {
        set has_routing_tracks 1
    }

    set layername [$layer getName]
    if { ![sc_cfg_exists pdk $sc_pdk {var} $sc_tool "${layername}_adjustment" $sc_stackup] } {
        utl::warn FLW 1 "Missing global routing adjustment for ${layername}"
    } else {
        set adjustment [lindex \
            [sc_cfg_get pdk $sc_pdk {var} $sc_tool "${layername}_adjustment" $sc_stackup] 0]
        utl::info FLW 1 \
            "Setting global routing adjustment for $layername to [expr { $adjustment * 100 }]%"
        set_global_routing_layer_adjustment $layername $adjustment
    }
}

# Only set these if routing tracks are available
if { $has_routing_tracks } {
    # Adjust macro extention
    set sc_grt_macro_extension [lindex [sc_cfg_tool_task_get {var} grt_macro_extension] 0]
    if { $sc_grt_macro_extension > 0 } {
        utl::info FLW 1 "Setting global routing macro extension to $sc_grt_macro_extension gcells"
        set_macro_extension $sc_grt_macro_extension
    }

    # Set min and max routing layers
    set sc_grt_signal_min_layer [sc_get_layer_name [lindex [sc_cfg_tool_task_get {var} grt_signal_min_layer] 0]]
    set sc_grt_signal_max_layer [sc_get_layer_name [lindex [sc_cfg_tool_task_get {var} grt_signal_max_layer] 0]]
    utl::info FLW 1 "Setting global routing signal routing layers to: ${sc_grt_signal_min_layer}-${sc_grt_signal_max_layer}"
    set_routing_layers -signal "${sc_grt_signal_min_layer}-${sc_grt_signal_max_layer}"

    set sc_grt_clock_min_layer [sc_get_layer_name [lindex [sc_cfg_tool_task_get {var} grt_clock_min_layer] 0]]
    set sc_grt_clock_max_layer [sc_get_layer_name [lindex [sc_cfg_tool_task_get {var} grt_clock_max_layer] 0]]
    utl::info FLW 1 "Setting global routing clock routing layers to: ${sc_grt_signal_min_layer}-${sc_grt_signal_max_layer}"
    set_routing_layers -clock "${sc_grt_clock_min_layer}-${sc_grt_clock_max_layer}"
}

######################
# Setup detailed route options
######################

if { [sc_cfg_tool_task_exists {var} detailed_route_default_via] } {
    foreach via [sc_cfg_tool_task_get {var} detailed_route_default_via] {
        utl::info FLW 1 "Marking $via a default detailed routing via"
        detailed_route_set_default_via $via
    }
}

if { [sc_cfg_tool_task_exists {var} detailed_route_unidirectional_layer] } {
    foreach layer [sc_cfg_tool_task_get {var} detailed_route_unidirectional_layer] {
        set layer_name [sc_get_layer_name $layer]
        utl::info FLW 1 "Marking $layer as a unidirectional routing layer"
        detailed_route_set_unidirectional_layer $layer
    }
}
