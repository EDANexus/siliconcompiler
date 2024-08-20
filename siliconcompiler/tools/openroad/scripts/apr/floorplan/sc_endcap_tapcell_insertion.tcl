
###########################
# Insert tie cells
###########################

foreach tie_type "high low" {
  if { [has_tie_cell $tie_type] } {
    insert_tiecells [get_tie_cell $tie_type]
  }
}
global_connect

###########################
# Tap Cells
###########################

if { [sc_cfg_tool_task_exists {file} ifp_tapcell] } {
  set tapcell_file [lindex [sc_cfg_tool_task_get {file} ifp_tapcell] 0]
  puts "Sourcing tapcell file: ${tapcell_file}"
  source $tapcell_file
  global_connect
}
