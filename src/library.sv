`ifndef sv_LIB
`define sv_LIB
`default_nettype none

module Decoder
  # (parameter int WIDTH = 8)
  (input  logic [$clog2(WIDTH + 1) - 1:0] I,
   input  logic                       en,
   output logic [WIDTH - 1:0]         D);

  assign D = (en) ? ('1 << I) : '0;
endmodule : Decoder

module BarrelShifter
  # (parameter int WIDTH = 8)
  (input  logic [WIDTH - 1:0]         V,
   input  logic [$clog2(WIDTH + 1) - 1:0] by,
   output logic [WIDTH - 1:0]         S);

  assign S = V << by;
endmodule : BarrelShifter

module Multiplexer
  # (parameter int WIDTH = 8)
  (input  logic [WIDTH - 1:0]         I,
   input  logic [$clog2(WIDTH) - 1:0] S,
   output logic                       Y);

  assign Y = I[S];
endmodule : Multiplexer

module Mux2to1
  # (parameter int WIDTH = 8)
  (input  logic [WIDTH - 1:0] I0,
   input  logic [WIDTH - 1:0] I1,
   input  logic               S,
   output logic [WIDTH - 1:0] Y);

  assign Y = S ? I1 : I0;
endmodule : Mux2to1

module MagComp
  # (parameter int WIDTH = 8)
  (input  logic [WIDTH - 1:0] A,
   input  logic [WIDTH - 1:0] B,
   output logic               AltB, AeqB, AgtB);

  assign AltB = (A < B);
  assign AeqB = (A == B);
  assign AgtB = (A > B);
endmodule : MagComp

module Comparator
  # (parameter int WIDTH = 8)
  (input  logic [WIDTH - 1:0] A,
   input  logic [WIDTH - 1:0] B,
   output logic               AeqB);

  assign AeqB = (A == B);
endmodule : Comparator

module Adder
  # (parameter int WIDTH = 8)
  (input  logic               cin,
   input  logic [WIDTH - 1:0] A, B,
   output logic               cout,
   output logic [WIDTH - 1:0] sum);

  logic [WIDTH:0] extendedSum;
  assign extendedSum = cin + A + B;
  assign sum = extendedSum[WIDTH - 1:0];
  assign cout = extendedSum[WIDTH];
endmodule : Adder

module Subtracter
  # (parameter int WIDTH = 8)
  (input  logic               bin,
   input  logic [WIDTH - 1:0] A, B,
   output logic               bout,
   output logic [WIDTH - 1:0] diff);

  logic [WIDTH:0] extendedDiff;
  assign extendedDiff = A - B - bin;
  assign diff = extendedDiff[WIDTH - 1:0];
  assign bout = extendedDiff[WIDTH];
endmodule : Subtracter

module DFlipFlop
  (input  logic D, clock, preset_L, reset_L,
   output logic Q);

  always_ff @(posedge clock, negedge preset_L, negedge reset_L) begin
    if (~preset_L)
      Q <= '1;
    else if (~reset_L)
      Q <= '0;
    else
      Q <= D;
  end
endmodule : DFlipFlop

module Register
  # (parameter int WIDTH = 8)
  (input  logic               en, clear, clock,
   input  logic [WIDTH - 1:0] D,
   output logic [WIDTH - 1:0] Q);

  always_ff @(posedge clock) begin
    if (en)
      Q <= D;
    else if (clear)
      Q <= '0;
  end
endmodule : Register

module Counter
  # (parameter int WIDTH = 8)
  (input  logic               en, clear, load, up, clock,
   input  logic [WIDTH - 1:0] D,
   output logic [WIDTH - 1:0] Q);

  always_ff @(posedge clock) begin
    if (clear)
      Q <= '0;
    else if (load)
      Q <= D;
    else if (en)
      Q <= (up) ? Q + 1 : Q - 1;
  end
endmodule : Counter

module ShiftRegisterSIPO
  # (parameter int WIDTH = 8)
  (input  logic               en, left, serial, clock,
   output logic [WIDTH - 1:0] Q);

  always_ff @(posedge clock) begin
    if (en)
      Q <= (left) ? {Q[WIDTH - 2:0], serial} : {serial, Q[WIDTH - 1:1]};
  end
endmodule : ShiftRegisterSIPO

module ShiftRegisterPIPO
  # (parameter int WIDTH = 8)
  (input  logic               en, left, load, clock,
   input  logic [WIDTH - 1:0] D,
   output logic [WIDTH - 1:0] Q);

  always_ff @(posedge clock)
    if (load)
      Q <= D;
    else if (en)
      Q <= (left) ? Q << 1 : Q >> 1;
endmodule : ShiftRegisterPIPO

module BarrelShiftRegister
  # (parameter int WIDTH = 8)
  (input  logic               en, load, clock,
   input  logic [1:0]         by,
   input  logic [WIDTH - 1:0] D,
   output logic [WIDTH - 1:0] Q);

  always_ff @(posedge clock) begin
    if (load)
      Q <= D;
    else if (en)
      Q <= (Q << by);
  end
endmodule : BarrelShiftRegister

module Synchronizer
  (input  logic async, clock,
   output logic sync);

  logic ff1Out;

  always_ff @(posedge clock) begin
    ff1Out <= async;
    sync <= ff1Out;
  end
endmodule : Synchronizer

module BusDriver
  # (parameter int WIDTH = 8)
  (input  logic               en,
   input  logic [WIDTH - 1:0] data,
   output logic [WIDTH - 1:0] buff,
   inout  tri   [WIDTH - 1:0] bus);

  assign buff = bus;
  assign bus = (en) ? data : 'z;
endmodule : BusDriver

module Memory
  # (parameter int DW = 8, int AW = 16)
  (input  logic [AW - 1:0] addr,
   input  logic            re, we, clock,
   inout  tri   [DW - 1:0] data);

  logic [DW - 1:0] M[1 << AW];

  always_ff @(posedge clock)
    M[addr] <= data;

  assign data = (re) ? M[addr] : 'z;
endmodule : Memory
`endif
