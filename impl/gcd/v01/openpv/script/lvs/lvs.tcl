source $env(G2_ROOT)/tcllib/openlib/openlib.tcl

set __t0 [clock seconds]

source setup.tcl

set blkname   $fvar(blkname)

set layout_spice ../layout/out/$blkname.spice
set schematic_v  ../schem/out/$blkname.pnl.v
set setup_file   $env(G2_ROOT)/../pdk/sky130/tech/netgen/sky130A_setup.tcl

lvs "$layout_spice $blkname" "$schematic_v $blkname" $setup_file rpt/lvs.log -json

set __secs [expr {max(1, [clock seconds] - $__t0)}]
set __h [expr {$__secs / 3600}]
set __m [expr {($__secs % 3600) / 60}]
set __s [expr {$__secs % 60}]
if {$__h > 0} {
  gset . runtime [format "%02dh:%02dm:%02ds" $__h $__m $__s]
} elseif {$__m > 0} {
  gset . runtime [format "%02dm:%02ds" $__m $__s]
} else {
  gset . runtime [format "%02ds" $__s]
}

if {[catch {exec ps -o rss= -p [pid]} __rss]} {
  gset . memory "NA"
} else {
  gset . memory [format "%.1f MB" [expr {[string trim $__rss] / 1024.0}]]
}

exit
