load $env(G2_ROOT)/bin/libtbcload.so
source $env(G2_ROOT)/tcllib/g2lib/g2lib.tbc

source setup.tcl

set sta_continue_on_error      1
set sta_report_default_digits  3

set blkname $fvar(blkname)

source libs.tcl
source read_golden.tcl

puts "Link..."
link_design $blkname

puts "report_ports..."
redirect rpt/golden_ports.rpt {report_ports}

source read_revised.tcl

puts "Link..."
link_design $blkname

puts "report_ports..."
redirect rpt/revised_ports.rpt {report_ports}

puts "Compare ports..."
set kin [open rpt/golden_ports.rpt r]
set golden_lines [lsearch -all -inline -not -exact [split [read $kin] "\n"] {}]
close $kin
set kin [open rpt/revised_ports.rpt r]
set revised_lines [lsearch -all -inline -not -exact [split [read $kin] "\n"] {}]
close $kin

set kout [open rpt/noneq.rpt w]
set noneq_count 0
foreach line $golden_lines {
  if {[lsearch -exact $revised_lines $line] == "-1"} {
    puts $kout "Non-equivalent: [lindex $line 1]"
    incr noneq_count
  }
}
foreach line $revised_lines {
  if {[lsearch -exact $golden_lines $line] == "-1"} {
    puts $kout "Non-equivalent: [lindex $line 1]"
    incr noneq_count
  }
}
close $kout
puts "Non-equivalent ports: $noneq_count"

set elapsed_secs [expr {int([sta::user_run_time] + 0.5)}]
set peak_mem_mb  [format "%.1f" [expr {[sta::memory_usage] / 1.0e6}]]
puts "Elapsed run time: $elapsed_secs"
puts "Peak Memory: $peak_mem_mb"

exit
