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

// Computes divIn1 / divIn2
module fpuDivider
  #(parameter int WIDTH = 16)
  (input  logic [WIDTH - 1:0] divIn1, divIn2,
   input  logic               start, clock, reset,
   output logic [WIDTH - 1:0] divOut,
   output logic               done);

  // Counts number of iterations.
  logic [$clog2(WIDTH + 1) - 1:0] shiftCounter;

  // Top WIDTH bits store the (partial) remainder, bottom WIDTH bits store the current quotient.
  logic [2 * WIDTH - 1:0] remShiftReg;
  logic [2 * WIDTH - 1:0] shiftedAQ;
  logic [WIDTH - 1:0] nextPartialRem;
  logic [WIDTH - 1:0] nextDivOut;
  logic [WIDTH:0] tempRemReg;
  logic [WIDTH - 1:0] latchedIn1;
  logic [WIDTH - 1:0] latchedIn2;

  logic compEn, compDone;

  logic restore;

  always_ff @(posedge clock, posedge reset) begin
    if (start) begin
      shiftCounter <= WIDTH;
      remShiftReg <= {WIDTH'(0), divIn1};
      latchedIn1 <= divIn1;
      latchedIn2 <= divIn2;
    end

    else if (compEn) begin
      shiftCounter <= shiftCounter - 1;
      remShiftReg <= {nextPartialRem, nextDivOut};
    end
  end

  assign shiftedAQ = remShiftReg << 1;

  // Remainder - divisor.
  assign tempRemReg = (shiftedAQ[2 * WIDTH - 1:WIDTH] - latchedIn2);

  // Check if subtraction overflowed (must restore).
  assign restore = (tempRemReg[WIDTH]);

  assign nextPartialRem = (restore) ? (shiftedAQ[2 * WIDTH - 1:WIDTH]) : tempRemReg;

  assign divOut = remShiftReg[WIDTH - 1:0];

  // Append 1 bit to quotient if no overflow, otherwise restore.
  assign nextDivOut = {shiftedAQ[WIDTH - 1:1] , ~restore};

  // Division is done when all dividend bits shifted.
  assign compDone = (shiftCounter == 1);

  fpuDividerFSM FSM(.*);

endmodule : fpuDivider

module fpuDividerFSM
  (input  logic clock, reset, compDone, start,
   output logic compEn, done);

  fpuDivState_t currState, nextState;

  always_ff @(posedge clock, posedge reset) begin
    if (reset) begin
      currState <= DIV_WAIT;
    end

    else begin
      currState <= nextState;
    end
  end

  always_comb begin
    unique case (currState)
      DIV_WAIT: nextState = (start) ? DIV_COMP : DIV_WAIT;

      DIV_COMP: nextState = (compDone) ? DIV_DONE : DIV_COMP;

      DIV_DONE: nextState = DIV_DONE;
    endcase
  end

  assign compEn = (currState == DIV_COMP);
  assign done = (currState == DIV_DONE);
endmodule : fpuDividerFSM

`endif
