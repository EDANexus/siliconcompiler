#######################
# Global Placement and Refinement of Pin Placement
#######################

if { [sc_design_has_placeable_ios] } {
  #######################
  # Global Placement (without considering IO placements)
  #######################

  if { $openroad_gpl_enable_skip_io } {
    utl::info FLW 1 "Performing global placement without considering IO"
    sc_global_placement -skip_io
  }

  ###########################
  # Refine Automatic Pin Placement
  ###########################

  if { ![sc_has_unplaced_instances] } {
    sc_pin_placement
  } else {
    utl::info FLW 1 "Skipping pin placements refinement due to unplaced instances"
  }
}
