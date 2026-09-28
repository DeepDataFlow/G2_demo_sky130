
set __t0 [exec date +%s]

source $env(G2_ROOT)/tcllib/openlib/openlib.tcl
source setup.tcl

set blkname   $fvar(blkname)
set tech_lef  $fvar(tech_lef)
set input_def ../blks/$blkname/out/$blkname.def

drc off

# Load cell GDS polygon data first so cells are established from GDS
# (if DEF is read first, cells load from .mag and can't be overwritten by gds read)
gds readonly true
gds rescale false
gds read $env(G2_ROOT)/pdk/sky130/stdcell/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
gds read $env(G2_ROOT)/pdk/sky130/stdcell/sky130_fd_sc_hdll/gds/sky130_fd_sc_hdll.gds

lef read $tech_lef
def read $input_def

load $blkname
select top cell

gds nodatestamp yes
gds write out/$blkname.gds

set __secs [expr {max(1, [exec date +%s] - $__t0)}]
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

exit 0
