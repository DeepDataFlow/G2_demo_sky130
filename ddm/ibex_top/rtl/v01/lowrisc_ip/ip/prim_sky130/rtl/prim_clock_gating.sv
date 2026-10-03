// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Common Library: Clock Gating cell
//
// The logic assumes that en_i is synchronized (so the instantiation site might need to put a
// synchronizer before en_i).
//
// ---------------------------------------------------------------------------
// G2_demo_sky130 modification: hard-coded sky130 integrated clock gating cell
// ---------------------------------------------------------------------------
// The upstream generic model (kept commented out below) describes the ICG as
// an always_latch + AND. Yosys maps flops via dfflibmap and logic via abc,
// but has no pass that maps a generic latch+AND onto a liberty ICG cell, so
// the latch was left unmapped as $_DLATCH_N_ in the netlist. Instantiating
// the library ICG directly gives a real, characterized clock gating cell that
// OpenROAD/CTS and OpenSTA recognize (clock_gating_integrated_cell :
// "latch_posedge_precontrol").
//
// sky130_fd_sc_hd__sdlclkp: GCLK = CLK & latch(GATE | SCE), latch is
// transparent while CLK is low.
//   CLK  <- clk_i      clock_gate_clock_pin
//   GATE <- en_i       clock_gate_enable_pin  (functional enable)
//   SCE  <- test_en_i  clock_gate_test_pin    (scan/test enable)
//   GCLK -> clk_o      clock_gate_out_pin
// Equivalent to the generic model: clk_o = clk_i & latch(en_i | test_en_i).
//
// The NoFpgaGate / FpgaBufGlobal parameters are dropped: they have no
// function in the generic model and no ibex instantiation overrides them.
//
// This file is technology specific (sky130_fd_sc_hd). Use the upstream
// prim_generic version for simulation-only or other-technology flows.

module prim_clock_gating (
  input        clk_i,
  input        en_i,
  input        test_en_i,
  output logic clk_o
);

  sky130_fd_sc_hd__sdlclkp_1 icg (
    .CLK  (clk_i),
    .GATE (en_i),
    .SCE  (test_en_i),
    .GCLK (clk_o)
  );

endmodule

// Upstream lowRISC generic model, kept for reference:
//
//module prim_clock_gating #(
//  parameter bit NoFpgaGate = 1'b0, // this parameter has no function in generic
//  parameter bit FpgaBufGlobal = 1'b1 // this parameter has no function in generic
//) (
//  input        clk_i,
//  input        en_i,
//  input        test_en_i,
//  output logic clk_o
//);
//
//  logic en_latch /* verilator clock_enable */;
//  always_latch begin
//    if (!clk_i) begin
//      en_latch = en_i | test_en_i;
//    end
//  end
//  assign clk_o = en_latch & clk_i;
//
//endmodule
