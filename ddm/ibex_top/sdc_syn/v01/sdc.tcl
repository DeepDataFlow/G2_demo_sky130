#==============================================================================
# ibex_top : synthesis constraints (sdc_syn v01)
#==============================================================================
# Mode   : functional (test_en_i = 0)
# Corner : synthesis corner ss_100C_1v60 (sky130_fd_sc_hd)
# Origin : netins initial SDC (impl/ibex_top/v01/netins/out/sdc.tcl), refined
#          with clock uncertainty/transition, I/O budgets, environment and
#          exceptions for static/test/reset ports.
#
# Clock period 40ns (25MHz @ ss/100C/1.60V) chosen from pre-layout STA on the
# yosys netlists: timing-driven mapping (abc -D -constr) reaches ~26ns reg2reg,
# leaving margin for placement wires and clock skew in APR.
#==============================================================================

set clk_period   40.0
set io_budget    [expr {$clk_period * 0.25}]   ;# external delay on I/O ports

#------------------------------------------------------------------------------
# Clock
#------------------------------------------------------------------------------
create_clock -name clk_i -period $clk_period [get_ports clk_i]

# Pre-CTS: ideal clock; uncertainty covers jitter + expected skew
set_clock_uncertainty -setup 1.0 [get_clocks clk_i]
set_clock_uncertainty -hold  0.2 [get_clocks clk_i]
set_clock_transition         0.5 [get_clocks clk_i]

#------------------------------------------------------------------------------
# Port groups
#------------------------------------------------------------------------------
# Quasi-static configuration: set once before/at reset release, not timed
set static_inputs [get_ports {
  hart_id_i[*]
  boot_addr_i[*]
  cheriot_enable_i[*]
  trvk_heap_base_addr_i[*]
  ram_cfg_icache_tag_i[*]
  ram_cfg_icache_data_i[*]
  fetch_enable_i[*]
  mcounteren_writable_i[*]
}]

# Resets (asynchronous assert)
set reset_inputs [get_ports {rst_ni scan_rst_ni}]

# Functional, clk_i-synchronous inputs
set sync_inputs [get_ports {
  instr_gnt_i instr_rvalid_i instr_rdata_i[*] instr_rdata_intg_i[*] instr_err_i
  data_gnt_i  data_rvalid_i  data_rdata_i[*]  data_rdata_intg_i[*]  data_tag_i data_err_i
  trvk_revbm_gnt_i trvk_revbm_rvalid_i trvk_revbm_rdata_i[*] trvk_revbm_rdata_intg_i[*] trvk_revbm_err_i
  irq_software_i irq_timer_i irq_external_i irq_fast_i[*] irq_nm_i
  scramble_key_valid_i scramble_key_i[*] scramble_nonce_i[*]
  debug_req_i
}]

# Functional, clk_i-synchronous outputs
set sync_outputs [get_ports {
  instr_req_o instr_addr_o[*]
  data_req_o data_we_o data_be_o[*] data_addr_o[*] data_wdata_o[*] data_wdata_intg_o[*] data_tag_o
  trvk_revbm_req_o trvk_revbm_addr_o[*]
  scramble_req_o
  crash_dump_o[*]
  double_fault_seen_o
  alert_minor_o alert_major_internal_o alert_major_bus_o
  core_sleep_o
}]

# Not constrained: tied to constants in this configuration (SecureIbex=0, no
# lockstep; ram_cfg_*_o are default responses). Constrain them if enabled.
#   instr_req_shadow_o instr_addr_shadow_o data_req_shadow_o data_we_shadow_o
#   data_be_shadow_o data_addr_shadow_o data_wdata_shadow_o
#   data_wdata_intg_shadow_o lockstep_cmp_en_o
#   ram_cfg_icache_tag_o ram_cfg_icache_data_o

#------------------------------------------------------------------------------
# I/O delays
#------------------------------------------------------------------------------
set_input_delay  -clock clk_i $io_budget $sync_inputs
set_output_delay -clock clk_i $io_budget $sync_outputs

# Static/reset/test inputs: constrained (so no port is left unconstrained),
# then excluded from timing by the false paths / case analysis below
set_input_delay  -clock clk_i 0 $static_inputs
set_input_delay  -clock clk_i 0 $reset_inputs
set_input_delay  -clock clk_i 0 [get_ports test_en_i]

#------------------------------------------------------------------------------
# Environment
#------------------------------------------------------------------------------
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 -pin X $sync_inputs
set_load 0.01 [all_outputs]

#------------------------------------------------------------------------------
# Exceptions
#------------------------------------------------------------------------------
# Functional mode: scan/test clock-gate override off
set_case_analysis 0 [get_ports test_en_i]

set_false_path -from $static_inputs
set_false_path -from $reset_inputs
