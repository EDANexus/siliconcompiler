
proc insert_fillers {} {
  upvar sc_filler sc_filler
  if { $sc_filler != "" } {
    filler_placement $sc_filler
  }

  check_placement -verbose

  global_connect
}

#######################
# Add Fillers
#######################

insert_fillers
