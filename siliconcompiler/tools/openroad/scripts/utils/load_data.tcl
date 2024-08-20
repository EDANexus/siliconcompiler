###############################
# Read timing libraries
###############################

set sc_scenarios [dict keys [sc_cfg_get constraint timing]]
set sc_delaymodel [sc_cfg_get asic delaymodel]

utl::info FLW 1 "Defining timing corners: $sc_scenarios"
define_corners {*}$sc_scenarios

# Read Liberty
foreach lib "$sc_targetlibs $sc_macrolibs" {
    foreach corner $sc_scenarios {
        foreach libcorner [sc_cfg_get constraint timing $corner libcorner] {
            if { [sc_cfg_exists library $lib output $libcorner $sc_delaymodel] } {
                foreach lib_file [sc_cfg_get library $lib output $libcorner $sc_delaymodel] {
                    puts "Reading liberty file for ${corner} ($libcorner): ${lib_file}"
                    read_liberty -corner $corner $lib_file
                }
                break
            }
        }
    }
}

###############################
# Read design files
###############################

if { [has_input_files odb "input layout odb"] } {
    foreach odb_file [get_input_files odb "input layout odb"] {
        puts "Reading ODB: ${odb_file}"
        read_db $odb_file
    }
} else {
    set sc_libtype [sc_cfg_get library $sc_mainlib asic libarch]
    set sc_techlef [sc_cfg_get pdk $sc_pdk aprtech openroad $sc_stackup $sc_libtype lef]

    # Read techlef
    puts "Reading techlef: ${sc_techlef}"
    read_lef $sc_techlef

    # Read Lefs
    foreach lib "$sc_targetlibs $sc_macrolibs" {
        foreach lef_file [sc_cfg_get library $lib output $sc_stackup lef] {
            puts "Reading lef: ${lef_file}"
            read_lef $lef_file
        }
    }

    if { [has_input_files def "input layout def"] } {
        foreach def_file [get_input_files def "input layout def"] {
            puts "Reading DEF: ${def_file}"
            read_def $def_file
        }
    } elseif { [has_input_files vg "input netlist verilog"] } {
        foreach netlist [get_input_files vg "input netlist verilog"] {
            puts "Reading netlist verilog: ${netlist}"
            read_verilog $netlist
        }
        link_design $sc_design
    } else {
        utl::error FLW 1 "No input files available"
    }

    # Handle global connect setup
    if { [sc_cfg_tool_task_exists {file} global_connect] } {
        foreach global_connect [sc_cfg_tool_task_get {file} global_connect] {
            puts "Loading global connect configuration: ${global_connect}"
            source $global_connect
        }
    }
}

###############################
# Read timing constraints
###############################

if { [has_input_files sdc "input constraint sdc"] } {
    foreach sdc [get_input_files sdc "input constraint sdc"] {
        puts "Reading SDC: ${sdc}"
        read_sdc $sdc
    }
} else {
    # fall back on default auto generated constraints file
    set sdc [sc_cfg_tool_task_get {file} opensta_generic_sdc]
    puts "Reading SDC: ${sdc}"
    utl::warn FLW 1 "Defaulting back to default SDC"
    read_sdc "${sdc}"
}
