load $env(G2_ROOT)/bin/libtbcload.so
source $env(G2_ROOT)/tcllib/g2lib/g2lib.tbc

set sw_timing_model [gvar . sw_timing_model]
set sw_exit         [gvar . sw_exit]

source setup.tcl

set sta_continue_on_error      1
set sta_report_default_digits  3

set blkname $fvar(blkname)

source libs.tcl
source read_verilog.tcl

puts "Link..."
link_design $blkname

puts "Spec..."
source read_spef.tcl

puts "SDC..."
source read_sdc.tcl

report_parasitic_annotation > rpt/report_parasitic_annotation.rpt

puts "check_setup..."
check_setup  > rpt/check_setup.rpt

puts "report_power..."
set_propagated_clock [all_clocks]
set_power_activity -input -activity 0.1
report_power > rpt/power_summary.rpt

redirect rpt/report_resource_usage.rpt {report_resource_usage}

exit

