
source $env(G2_ROOT)/tcllib/openlib/openlib.tcl

source setup.tcl

set blkname $fvar(blkname)
set def    ../blks/$blkname/out/$blkname.def

# LEF
read_lef $fvar(tech_lef)
foreach lef $fvar(lefs) {
  read_lef $lef
}

read_def $def

write_verilog -include_pwr_gnd out/$blkname.pnl.v

gset . runtime [format_run_time]
gset . memory  [format_memory_usage]


exit


