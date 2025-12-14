/*
* divider.sv: An implementation of a rudimentary sequential divider.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef sv_DIV
`define sv_DIV

`include "constants.sv"
`include "library.sv"

typedef enum logic [1:0] {
  DIV_WAIT,
  DIV_COMP,
  DIV_DONE
} fpuDivState_t;

module fpuDivider
  #(parameter int WIDTH = 16)
  (input  logic [WIDTH - 1:0] divIn1, divIn2,
   input  logic               start, clock, reset,
   output logic [WIDTH - 1:0] divOut,
   output logic               done);
endmodule : fpuDivider

module fpuDividerFSM
  (input  logic clock, reset, compDone, start,
   output logic compEn,
   output logic done);
endmodule : fpuDividerFSM

`endif
