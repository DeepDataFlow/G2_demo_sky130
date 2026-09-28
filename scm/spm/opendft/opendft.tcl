source $env(G2_ROOT)/tcllib/openlib/openlib.tcl
source setup.tcl

set blkname $fvar(blkname)

# LEF
read_lef $fvar(tech_lef)
foreach lef $fvar(lefs) {
  read_lef $lef
}

foreach lib $fvar(target_lib) {
  read_liberty $lib
}

# Netlist
source read_verilog.tcl
link_design -hier $blkname


# SDC
#source sdc_dft/sdc.tcl
#
#
#set_dft_config -max_length 10
#
#scan_replace
#
#report_dft_plan -verbose
#
#
#execute_dft_plan

write_verilog out/$blkname.v

gset . runtime [format_run_time]
gset . memory  [format_memory_usage]

if {$fvar(sw_exit) eq "1"} {
  exit
}
