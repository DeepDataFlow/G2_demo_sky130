// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// sky130 single-port SRAM: drop-in replacement for prim_generic/prim_ram_1p
// that maps each supported Width x Depth onto a FakeRAM hard macro.
//
// Supported shapes (ibex icache, ICache=1, MemECC=0):
//   tag  RAM : 22 x 256  -> fakeram_256x22
//   data RAM : 64 x 256  -> fakeram_256x64
//
// The macros have no write mask, so only full-word writes are supported
// (the ibex icache always drives wmask_i to all ones).

`include "prim_assert.sv"

module prim_ram_1p import prim_ram_1p_pkg::*; #(
  parameter  int Width           = 32, // bit
  parameter  int Depth           = 128,
  parameter  int DataBitsPerMask = 1, // Number of data bits per bit of write mask
  parameter      MemInitFile     = "", // VMEM file to initialize the memory with

  localparam int Aw              = $clog2(Depth)  // derived parameter
) (
  input  logic             clk_i,
  input  logic             rst_ni,

  input  logic             req_i,
  input  logic             write_i,
  input  logic [Aw-1:0]    addr_i,
  input  logic [Width-1:0] wdata_i,
  input  logic [Width-1:0] wmask_i,
  output logic [Width-1:0] rdata_o, // Read data. Data is returned one cycle after req_i is high.
  input  ram_1p_cfg_req_t  cfg_i,
  output ram_1p_cfg_rsp_t  cfg_o
);

  logic unused_signals;
  assign unused_signals = ^{cfg_i, rst_ni, wmask_i};
  assign cfg_o          = RAM_1P_CFG_RSP_DEFAULT;

  if (Width == 22 && Depth == 256) begin : gen_256x22
    fakeram_256x22 u_mem (
      .clk     (clk_i),
      .ce_in   (req_i),
      .we_in   (write_i),
      .addr_in (addr_i),
      .wd_in   (wdata_i),
      .rd_out  (rdata_o)
    );
  end else if (Width == 64 && Depth == 256) begin : gen_256x64
    fakeram_256x64 u_mem (
      .clk     (clk_i),
      .ce_in   (req_i),
      .we_in   (write_i),
      .addr_in (addr_i),
      .wd_in   (wdata_i),
      .rd_out  (rdata_o)
    );
  end else begin : gen_unsupported
    $error("prim_ram_1p (sky130): no SRAM macro for Width=%0d Depth=%0d", Width, Depth);
  end

endmodule
