/*
* multiplier.sv: Sequential, unsigned multiplier for multiplying mantissas. Process is started by
* asserting the start signal (for one clock cycle). The result is ready when the done signal is asserted.
* To start computation with new inputs, reset must first be asserted, then the
* same start process.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef sv_MUL
`define sv_MUL

`include "constants.sv"
`include "library.sv"

typedef enum logic[1:0] {
  WAIT,
  COMP,
  DONE
} fpuMultiplyState_t;

module fpuMultiplier16
  (input  logic[`FP16_FRACW - 1:0] mulIn1, mulIn2,
   input  logic                    start,
   input  logic                    clock, reset,
   output logic[2 * `FP16_FRACW - 1:0] mulOut,
   output logic                    done);

  // All components share one enable signal.
  logic compEn;

  // TODO: Optimize logic so that smaller input on bottom.
  logic compDone;
  logic [`FP16_FRACW - 1:0] shift;
  logic [2 * `FP16_FRACW - 1:0] adderOut;
  logic [2 * `FP16_FRACW - 1:0] adderIn;
  logic [`FP16_FRACW - 1:0] latchedIn1;
  logic [`FP16_FRACW - 1:0] storedIn2;

  // Shift register for mulIn2.
  always_ff @(posedge clock) begin
    if (start) begin
      storedIn2 <= mulIn2;
    end
    else if (compEn) begin
      storedIn2 <= storedIn2 >> 1;
    end
  end

  assign compDone = (shift == 9'd9);

  // Registers to latch input value, in case they change during computation.
  Register #(.WIDTH(`FP16_FRACW)) inReg1(.en(start), .clear('0), .clock,
                                         .D(mulIn1), .Q(latchedIn1));
  // Register for output value.
  Register #(.WIDTH(2 * `FP16_FRACW)) outReg(.en(compEn), .clear(reset | start), .clock,
                                             .D(adderOut), .Q(mulOut));

  // Counter for shift amount.
  Counter #(.WIDTH(`FP16_FRACW)) shiftCounter(.en(compEn), .clear(start), .load('0),
                                              .up('1), .clock, .D('0), .Q(shift));

  // Adder to calculate intermediate sums.
  assign adderIn = (storedIn2[0]) ? ({`FP16_FRACW'd0, latchedIn1} << shift) : '0;
  Adder #(.WIDTH(2 * `FP16_FRACW)) adder(.cin('0), .A(mulOut), .B(adderIn),
                                         .cout(), .sum(adderOut));

  fpuMultiplierFSM FSM(.*);
endmodule : fpuMultiplier16

module fpuMultiplierFSM
  (input  logic clock, reset, compDone, start,
   output logic compEn,
   output logic done);

  fpuMultiplyState_t currState, nextState;

  always_ff @(posedge clock, posedge reset) begin
    if (reset) begin
      currState <= WAIT;
    end
    else begin
      currState <= nextState;
    end
  end

  always_comb begin
    compEn = 0;
    done = 0;
    unique case (currState)
      WAIT: nextState = (start) ? COMP : WAIT;

      COMP: begin
        nextState = (compDone) ? DONE : COMP;
        compEn = 1;
      end

      DONE: begin
        nextState = DONE;
        done = 1;
      end
    endcase
  end
endmodule : fpuMultiplierFSM
`endif
