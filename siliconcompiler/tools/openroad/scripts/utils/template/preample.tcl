###############################
# Reading SC Schema
###############################

source ./sc_manifest.tcl > /dev/null

##############################
# Source OpenROAD driver
###############################

source "[sc_cfg_tool_task_get refdir]/utils/template/sc_driver.tcl"

##############################
# Source prescript scripts
###############################

utl::push_metrics_stage "sc__prestep__{}"
foreach sc_pre_script [sc_cfg_tool_task_get prescript] {
    puts "Sourcing prescript: ${sc_pre_script}"
    source -echo $sc_pre_script
}
utl::pop_metrics_stage

##############################
# Run primary task
###############################

##############################
# Source postscript scripts
###############################

utl::push_metrics_stage "sc__poststep__{}"
foreach sc_post_script [sc_cfg_tool_task_get postscript] {
    puts "Sourcing postscript: ${sc_post_script}"
    source -echo $sc_post_script
}
utl::pop_metrics_stage

###############################
# Write Design Data
###############################

utl::push_metrics_stage "sc__write__{}"
#source "$sc_refdir/sc_write.tcl"
utl::pop_metrics_stage
