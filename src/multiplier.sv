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

typedef enum logic[1:0] {
  MUL_WAIT,
  MUL_COMP,
  MUL_DONE
} fpuMultiplyState_t;

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

module radix16Mult
  #(parameter int WIDTH = 32,
    parameter int OUTWIDTH = (WIDTH << 1))
   (input  logic [WIDTH - 1:0]    mulIn1, mulIn2,
    input  logic                  clock, reset, start,
    output logic [OUTWIDTH - 1:0] mulOut,
    output logic                  done);

   localparam int ITERS = $ceil(WIDTH / 4);

   // Pad MSB of multiplier with four zeros.
   logic [WIDTH + 3:0] storedMultiplier_shiftReg;

   // Four radix bits for radix-16.
   logic [3:0] radixBits;

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
   assign addend = (currPP << (iterCounter << 2));

   always_ff @(posedge clock) begin
     if (start) begin
       storedMultiplier_shiftReg <= {4'd0, mulIn2};
       iterCounter <= 0;
       mulOut <= 0;
       extMultiplicand <= mulIn1;
     end

     else if (compEn) begin
       storedMultiplier_shiftReg <= (storedMultiplier_shiftReg >> 4);
       iterCounter <= (iterCounter + 1);
       mulOut <= mulOut + addend;
     end
   end

   assign radixBits = storedMultiplier_shiftReg[3:0];

   always_comb begin
     unique case (radixBits)
       4'b0000: currPP = 0;
       4'b0001: currPP = extMultiplicand;
       4'b0010: currPP = (extMultiplicand << 1);
       4'b0011: currPP = (extMultiplicand << 1) + extMultiplicand;
       4'b0100: currPP = (extMultiplicand << 2);
       4'b0101: currPP = (extMultiplicand << 2) + extMultiplicand;
       4'b0110: currPP = (extMultiplicand << 2) + (extMultiplicand << 1);
       4'b0111: currPP = (extMultiplicand << 2) + (extMultiplicand << 1) + extMultiplicand;
       4'b1000: currPP = (extMultiplicand << 3);
       4'b1001: currPP = (extMultiplicand << 3) + extMultiplicand;
       4'b1010: currPP = (extMultiplicand << 3) + (extMultiplicand << 1);
       4'b1011: currPP = (extMultiplicand << 3) + (extMultiplicand << 1) + extMultiplicand;
       4'b1100: currPP = (extMultiplicand << 3) + (extMultiplicand << 2);
       4'b1101: currPP = (extMultiplicand << 3) + (extMultiplicand << 2) + extMultiplicand;
       4'b1110: currPP = (extMultiplicand << 3) + (extMultiplicand << 2) + (extMultiplicand << 1);
       4'b1111: currPP = (extMultiplicand << 3) + (extMultiplicand << 2) + (extMultiplicand << 1) + extMultiplicand;
     endcase
   end

  fpuMultiplierFSM FSM(.*);
endmodule : radix16Mult
`endif
