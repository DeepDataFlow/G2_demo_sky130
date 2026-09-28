source $env(G2_ROOT)/tcllib/openlib/openlib.tcl
source setup.tcl
source $fvar(tech_fvar)
set blkname $fvar(blkname)

set g2_start_time [clock seconds]

# LEF
read_lef $fvar(tech_lef)
foreach lef $fvar(lefs) {
  read_lef $lef
}

# Liberty (needed by read_spef/analyze_power_grid for cell power characterization)
foreach lib $fvar(target_lib) {
  read_liberty $lib
}

# Design (routed checkpoint pulled from DDM apr_finish via blks/$blkname)
read_db ../blks/$blkname/out/session.db

# Parasitics
read_spef $fvar(spef)

source $fvar(layer_rc)
set_wire_rc -signal -layer $wire_rc_layer
set_wire_rc -clock  -layer $wire_rc_layer_clk

if {![info exist fvar(vdd_nets)] || $fvar(vdd_nets) eq ""} {
  set fvar(vdd_nets) VDD
}
if {![info exist fvar(gnd_nets)] || $fvar(gnd_nets) eq ""} {
  set fvar(gnd_nets) VSS
}

puts "Static IR drop analysis..."
# Ported from openlane/scripts/openroad/irdrop.tcl
if {[info exist fvar(vsrc_loc_files)] && $fvar(vsrc_loc_files) ne ""} {
  foreach {net vsrc_file} $fvar(vsrc_loc_files) {
    set arg_list [list]
    lappend arg_list -net $net
    lappend arg_list -voltage_file rpt/${net}_ir.rpt
    lappend arg_list -vsrc $vsrc_file
    analyze_power_grid {*}$arg_list
  }
} else {
  foreach net $fvar(vdd_nets) {
    analyze_power_grid -net $net -voltage_file rpt/VDD_ir.rpt
  }
  foreach net $fvar(gnd_nets) {
    analyze_power_grid -net $net -voltage_file rpt/VSS_ir.rpt
  }
}


puts "Exiting OpenIR on [clock format [clock seconds]]"
puts "Total real time: [expr {[clock seconds] - $g2_start_time}] sec"

exit
