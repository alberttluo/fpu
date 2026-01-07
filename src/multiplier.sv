/*
* multiplier.sv: Unsigned multiplier for multiplying mantissas. Process is started by
* asserting the start signal (for one clock cycle). The result is ready when the done signal is asserted.
* To start computation with new inputs, reset must first be asserted, then the
* same start process.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef sv_MUL
`define sv_MUL

`include "library.sv"

typedef enum logic[1:0] {
  MUL_WAIT,
  MUL_COMP,
  MUL_DONE
} fpuMultiplyState_t;

module fpuMultiplier
  #(parameter int FRAC_WIDTH = 10)
  (input  logic[FRAC_WIDTH:0]     mulIn1, mulIn2,
   input  logic                    start,
   input  logic                    clock, reset,
   output logic[2 * FRAC_WIDTH + 1:0] mulOut,
   output logic                    done);

  // All components share one enable signal.
  logic compEn;

  // TODO: Optimize logic so that smaller input on bottom.
  logic compDone;
  logic [FRAC_WIDTH:0] shift;
  logic [2 * FRAC_WIDTH + 1:0] adderOut;
  logic [2 * FRAC_WIDTH + 1:0] adderIn;
  logic [FRAC_WIDTH:0] latchedIn1;
  logic [FRAC_WIDTH:0] storedIn2;

  // Shift register for mulIn2.
  always_ff @(posedge clock) begin
    if (start) begin
      storedIn2 <= mulIn2;
    end
    else if (compEn) begin
      storedIn2 <= storedIn2 >> 1;
    end
  end

  assign compDone = (storedIn2 == 0);

  // Registers to latch input value, in case they change during computation.
  Register #(.WIDTH(FRAC_WIDTH + 1)) inReg1(.en(start), .clear('0), .clock,
                                         .D(mulIn1), .Q(latchedIn1));
  // Register for output value.
  Register #(.WIDTH(2 * (FRAC_WIDTH + 1))) outReg(.en(compEn), .clear(reset | start), .clock,
                                             .D(adderOut), .Q(mulOut));

  // Counter for shift amount.
  Counter #(.WIDTH(FRAC_WIDTH + 1)) shiftCounter(.en(compEn), .clear(start), .load('0),
                                              .up('1), .clock, .D('0), .Q(shift));

  // Adder to calculate intermediate sums.
  assign adderIn = (storedIn2[0]) ? ({{FRAC_WIDTH{1'b0}}, latchedIn1} << shift) : '0;
  Adder #(.WIDTH(2 * (FRAC_WIDTH + 1))) adder(.cin('0), .A(mulOut), .B(adderIn),
                                         .cout(), .sum(adderOut));

  fpuMultiplierFSM FSM(.*);
endmodule : fpuMultiplier

module fpuMultiplierFSM
  (input  logic clock, reset, compDone, start,
   output logic compEn,
   output logic done);

  fpuMultiplyState_t currState, nextState;

  always_ff @(posedge clock, posedge reset) begin
    if (reset) begin
      currState <= MUL_WAIT;
    end
    else begin
      currState <= nextState;
    end
  end

  always_comb begin
    compEn = 0;
    done = 0;
    unique case (currState)
      MUL_WAIT: nextState = (start) ? MUL_COMP : MUL_WAIT;

      MUL_COMP: begin
        nextState = (compDone) ? MUL_DONE : MUL_COMP;
        compEn = 1;
      end

      MUL_DONE: begin
        nextState = MUL_DONE;
        done = 1;
      end
    endcase
  end
endmodule : fpuMultiplierFSM

// 24-bit Radix-4 multiplier for fp32 (and fp16).
module radix4Mult32
  #(parameter int FRACW = 23,
    parameter int WIDTH = FRACW + 1,
    parameter int OUTWIDTH = (WIDTH << 1))
   (input  logic [WIDTH - 1:0]    mulIn1, mulIn2,
    input  logic                  clock, reset, start,
    output logic [OUTWIDTH - 1:0] mulOut,
    output logic                  done);

   localparam int ITERS = (WIDTH / 2 + 1);

   // Pad MSB of multiplier with two zeros;
   logic [WIDTH + 1:0] storedMultiplier_shiftReg;

   // Two radix bits for radix-4.
   logic [1:0] radixBits;

   // Counter for number of iterations.
   int unsigned iterCounter;
   logic compDone;
   logic compEn;
   assign compDone = (iterCounter == ITERS + 1);

   // Extended multiplicand so signed arithmetic works properly.
   logic [OUTWIDTH - 1:0] extMultiplicand;

   // Current partial product;
   logic [OUTWIDTH - 1:0] currPP;

   // Addend from partial product.
   logic [OUTWIDTH - 1:0] addend;
   assign addend = (currPP << (iterCounter << 1));

   always_ff @(posedge clock) begin
     if (start) begin
       storedMultiplier_shiftReg <= {2'b00, mulIn2};
       iterCounter <= 0;
       mulOut <= 0;
       extMultiplicand <= mulIn1;
     end

     else if (compEn) begin
       storedMultiplier_shiftReg <= (storedMultiplier_shiftReg >> 2);
       iterCounter <= (iterCounter + 1);
       mulOut <= mulOut + addend;
     end
   end

   assign radixBits = storedMultiplier_shiftReg[1:0];

   always_comb begin
     unique case (radixBits)
       2'b00: currPP = 0;
       2'b01: currPP = extMultiplicand;
       2'b10: currPP = (extMultiplicand << 1);
       2'b11: currPP = (extMultiplicand << 1) + extMultiplicand;
     endcase
   end

  fpuMultiplierFSM FSM(.*);
endmodule : radix4Mult32
`endif
