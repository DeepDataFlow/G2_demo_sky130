#==============================================================================
# yosys_adv.tcl : timing-driven synthesis (advanced)
#==============================================================================
# Differences from yosys.tcl (area-oriented basic flow):
#   1. synth -booth : Booth-encoded multipliers (ibex_multdiv_fast)
#   2. abc -D <ps>  : delay-targeted technology mapping
#   3. abc -constr  : driving cell + output load. Required: without it ABC
#                     skips buffer/upsize/dnsize and -D alone changes nothing
#                     (unbuffered high-fanout nets dominate the delay).
#
# Yosys cannot read SDC for optimization, so the ABC settings are derived
# from the synthesis SDC (sdc_syn/sdc.tcl) to keep a single source of truth:
#   delay target = clk_period - io_budget - setup uncertainty
# (ABC only sees each module's internal logic, so the external I/O budget
#  and clock uncertainty are taken off the period.)
#==============================================================================

yosys -import

set t0 [clock milliseconds]

# Derive ABC timing settings from sdc_syn
# {{{
proc sdc_value {sdc pattern} {
  if {![regexp -line $pattern $sdc -> value]} {
    error "yosys_adv.tcl: cannot find '$pattern' in sdc_syn/sdc.tcl"
  }
  return $value
}
set fh  [open sdc_syn/sdc.tcl r]
set sdc [read $fh]
close $fh

set clk_period  [sdc_value $sdc {^set\s+clk_period\s+([0-9.]+)}]
set io_ratio    [sdc_value $sdc {^set\s+io_budget\s+\[expr\s+\{\$clk_period\s*\*\s*([0-9.]+)\}\]}]
set uncertainty [sdc_value $sdc {^set_clock_uncertainty\s+-setup\s+([0-9.]+)}]
set drive_cell  [sdc_value $sdc {^set_driving_cell\s+-lib_cell\s+(\S+)}]
set out_load    [sdc_value $sdc {^set_load\s+([0-9.]+)}]

set abc_delay_ps [expr {int(($clk_period * (1.0 - $io_ratio) - $uncertainty) * 1000)}]

set fh [open abc.constr w]
puts $fh "set_driving_cell $drive_cell"
puts $fh "set_load $out_load"
close $fh

puts "yosys_adv: clk_period=${clk_period}ns io_ratio=$io_ratio uncertainty=${uncertainty}ns"
puts "yosys_adv: abc -D $abc_delay_ps  (driving cell $drive_cell, load $out_load pF)"
# }}}

source setup.tcl

set target_lib $fvar(target_lib)
set blkname    $fvar(blkname)


foreach lib $target_lib {
    read_liberty -lib $lib
}

source read_rtl.tcl

hierarchy -check -top $blkname
#hierarchy -top $blkname

uniquify

#yosys proc
#techmap
synth -booth -noabc

set liberty_flags {}
foreach lib $target_lib {
    lappend liberty_flags -liberty $lib
}
dfflegalize -cell {$_DFFE_PP_} 01 -cell {$_DFFSR_NNN_} 01 -cell {$_DFFSR_PNN_} 01 \
    -cell {$_DFF_NN0_} 01 -cell {$_DFF_PN0_} 01 -cell {$_DFF_PN1_} 01 -cell {$_DFF_P_} 01 \
    {t:$_DFF*} {t:$_SDFF*}
dfflibmap {*}$liberty_flags

abc -D $abc_delay_ps -constr abc.constr {*}$liberty_flags -dont_use *lpflow* -dont_use sky130_fd_sc_hd__a211oi_*

clean

autoname

write_verilog -noattr -noexpr -nohex -nodec -noparam out/$blkname.v

source script/util/util.tcl

report_ports
report_registers
report_hier
set unmap_count [report_unmap rpt/unmap.rpt]

set in_count   [sel_count ${blkname}/i:*]
set out_count  [sel_count ${blkname}/o:*]
# flops: DFF* (TSMC-style) or sky130 *__df*/*__edf*/*__sdf* (dfrtp, edfxtp, ...)
set reg_count  [sel_count t:DFF* t:*__*df*]
set inst_count [sel_count t:*]


exec gset . runtime [get_elapsed_time]
exec gset . memory  [get_memory_usage]
exec gset . input_ports $in_count
exec gset . output_ports $out_count
exec gset . reg_count $reg_count
exec gset . inst_count $inst_count
exec gset . unmap_count $unmap_count

exec sd -e "ports2svg rpt/ports.rpt out/ports.svg $blkname"

report_port_connection rpt/port_conn.rpt



