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

report_parasitic_annotation -report_unannotated > rpt/report_parasitic_annotation.rpt

puts "QoR..."
g2_opensta_qor
puts "report_cells..."
#redirect rpt/report_cells.rpt {report_cells}
redirect rpt/report_bbox.rpt             {report_bbox}
redirect rpt/report_missing_libcell.rpt  {report_missing_libcell}
redirect rpt/report_resource_usage.rpt   {report_resource_usage}

#puts "report_power..."
#report_power > rpt/report_power.rpt

puts "report_ports..."
redirect rpt/report_ports.rpt {report_ports}
bit2bus rpt/report_ports.rpt rpt/bus.rpt
gen_ports_rpt rpt/ports.rpt


puts "report_hier..."
redirect rpt/report_hier.rpt  {report_hier}


puts "check_setup..."
check_setup  > rpt/check_setup.rpt


puts "report_timing..."
group_path -name reg2reg -from [all_registers] -to [all_registers]
group_path -name in2reg  -from [all_inputs]    -to [all_registers]
group_path -name reg2out -from [all_registers] -to [all_outputs]
group_path -name in2out  -from [all_inputs]    -to [all_outputs]



puts "report_global_timing..."
redirect rpt/report_global_timing.rpt {report_global_timing}

report_checks -path_delay max -format full_clock_expanded \
               -fields {cap slew}  \
               -endpoint_path_count 20 \
               -no_line_split \
               -unique_paths_to_endpoint > rpt/report_timing.rpt

report_check_types -max_slew        > rpt/max_tran.rpt 
report_check_types -min_pulse_width > rpt/min_pulse_width.rpt 
report_check_types -min_period      > rpt/min_period.rpt 

report_check_types -violators \
                   -format end \
                   -max_delay \
                   -recovery \
                                    > rpt/report_constraint.rpt 


if {$sw_timing_model eq "1"} {
  write_timing_model out/$blkname.lib
}

if {$sw_exit eq "1"} {
  exit
}
