
set sc_grt_arguments []
if { $openroad_grt_allow_congestion == "true" } {
  lappend sc_grt_arguments "-allow_congestion"
}
if { $openroad_grt_allow_overflow == "true" } {
  lappend sc_grt_arguments "-allow_overflow"
}

global_route -guide_file "./route.guide" \
  -congestion_iterations $openroad_grt_overflow_iter \
  -congestion_report_file "reports/${sc_design}_congestion.rpt" \
  -verbose \
  {*}$sc_grt_arguments
