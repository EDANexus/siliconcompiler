###############################
# Write design information
###############################

write_db "outputs/${sc_design}.odb"
write_def "outputs/${sc_design}.def"
write_verilog -include_pwr_gnd "outputs/${sc_design}.vg"

###############################
# Write timing information
###############################

write_sdc "outputs/${sc_design}.sdc"
