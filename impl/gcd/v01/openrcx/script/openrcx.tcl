source $env(G2_ROOT)/tcllib/openlib/openlib.tcl
source setup.tcl

set blkname $fvar(blkname)
set pjroot  [get_pjroot]

# Load post-finish routed database
read_db apr_finish/out/session.db

# Reload MMMC and SDC for timing context
source ../openroad/init/mmmc.tcl
read_sdc -echo ../openroad/init/sdc_apr_func/sdc.tcl

# Read SPEF corners from project spec
set fh [open $pjroot/spec/signoff_scens/spef.cfg r]
set _raw [read $fh]
close $fh
set spef_corners {}
foreach _line [split $_raw "\n"] {
  set _line [string trim $_line]
  if {$_line ne "" && ![string match "#*" $_line]} {
    lappend spef_corners $_line
  }
}

# Extract and write one SPEF per corner
# Nangate45 has a single RCX model; all corners map to index 0
foreach corner $spef_corners {
  define_process_corner -ext_model_index 0 $corner
  extract_parasitics -ext_model_file $fvar($corner,rcx_rules)
  set spef_out out/$blkname.[string map {, _} $corner].spef
  write_spef $spef_out
  exec gzip -f $spef_out
  puts "Written: ${spef_out}.gz"
}

gset . runtime [format_run_time]
gset . memory  [format_memory_usage]

exit
