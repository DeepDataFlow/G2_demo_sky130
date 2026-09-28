
set __t0 [exec date +%s]

source $env(G2_ROOT)/tcllib/openlib/openlib.tcl
source setup.tcl

set blkname   $fvar(blkname)
set tech_lef  $fvar(tech_lef)
set input_def ../blks/$blkname/out/$blkname.def

lef read $tech_lef
foreach lef $fvar(lefs) {
  lef read $lef
}

def read $input_def

load $blkname -dereference

exec rm -rf magic_ext
file mkdir magic_ext
cd magic_ext

extract do local
extract no capacitance
extract no coupling
extract no resistance
extract no adjust
extract unique
extract

ext2spice lvs
ext2spice -o ../out/$blkname.spice $blkname.ext

set __secs [expr {max(1, [exec date +%s] - $__t0)}]
set __h [expr {$__secs / 3600}]
set __m [expr {($__secs % 3600) / 60}]
set __s [expr {$__secs % 60}]
if {$__h > 0} {
  gset .. runtime [format "%02dh:%02dm:%02ds" $__h $__m $__s]
} elseif {$__m > 0} {
  gset .. runtime [format "%02dm:%02ds" $__m $__s]
} else {
  gset .. runtime [format "%02ds" $__s]
}

if {[catch {exec ps -o rss= -p [pid]} __rss]} {
  gset .. memory "NA"
} else {
  gset .. memory [format "%.1f MB" [expr {[string trim $__rss] / 1024.0}]]
}


exit
