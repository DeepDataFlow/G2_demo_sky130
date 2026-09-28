
set __t0 [exec date +%s]

source $env(G2_ROOT)/tcllib/openlib/openlib.tcl
source setup.tcl

set blkname   $fvar(blkname)

set gds_file ../gdsmerge/out/$blkname.gds
set drc_rpt  rpt/drc.rpt

gds read $gds_file

load $blkname
select top cell
drc euclidean on
drc style drc(full)
drc check

set drcresult [drc listall why]
set fout [open $drc_rpt w]
set oscale [cif scale out]

set count 0
puts $fout "$blkname"
puts $fout "----------------------------------------"
foreach {errtype coordlist} $drcresult {
    puts $fout $errtype
    puts $fout "----------------------------------------"
    foreach coord $coordlist {
        set bllx [expr {$oscale * [lindex $coord 0]}]
        set blly [expr {$oscale * [lindex $coord 1]}]
        set burx [expr {$oscale * [lindex $coord 2]}]
        set bury [expr {$oscale * [lindex $coord 3]}]
        set coords [format " %.3fum %.3fum %.3fum %.3fum" $bllx $blly $burx $bury]
        puts $fout "$coords"
        set count [expr {$count + 1}]
    }
    puts $fout "----------------------------------------"
}

puts $fout "\[INFO\]: COUNT: $count"
puts $fout "\[INFO\]: Should be divided by 3 or 4"
close $fout

puts stdout "\[INFO\]: COUNT: $count"
puts stdout "\[INFO\]: Should be divided by 3 or 4"
puts stdout "\[INFO\]: DRC done -> $drc_rpt"

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
