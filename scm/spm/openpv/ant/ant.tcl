

source $env(G2_ROOT)/tcllib/openlib/openlib.tcl

source setup.tcl

set blkname   $fvar(blkname)

set def      ../blks/$blkname/out/$blkname.def
set rpt      rpt/ant.rpt


# LEF
read_lef $fvar(tech_lef)
foreach lef $fvar(lefs) {
  read_lef $lef
}

read_def $def

check_antennas -verbose -report_file $rpt

gset . runtime [format_run_time]
gset . memory  [format_memory_usage]



exit
