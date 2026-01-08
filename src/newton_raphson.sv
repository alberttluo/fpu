/*
* newton_raphson.sv: Division by Newton-Raphson reciprocal approximation.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef NEWTON_RAPHSON_SV
`define NEWTON_RAPHSON_SV

`include "fmad.sv"

typedef enum logic [2:0] {
  NR_WAIT,
  NR_FMAD_KICK,
  NR_FMAD_WAIT,
  NR_MUL_KICK,
  NR_MUL_WAIT,
  NR_DONE
} nrrState_t;

module nrrFSM
  (input  logic start, reset, clock,
   input  logic fmadDone, mulDone, itersDone,
   output logic fmadStart, mulStart,
   output logic compEn, nrrDone);

  nrrState_t currState, nextState;

  always_ff @(posedge clock, posedge reset) begin
    if (reset) begin
      currState <= NR_WAIT;
    end
    else begin
      currState <= nextState;
    end
  end

  always_comb begin
    fmadStart = 0;
    mulStart = 0;
    compEn = 0;
    nrrDone = 0;

    unique case (currState)
      NR_WAIT: nextState = (start) ? NR_FMAD_KICK : NR_WAIT;

      NR_FMAD_KICK: begin
        fmadStart = 1;
        nextState = NR_FMAD_WAIT;
      end

      NR_FMAD_WAIT: nextState = (fmadDone) ? NR_MUL_KICK : NR_FMAD_WAIT;

      NR_MUL_KICK: begin
        mulStart = 1;
        nextState = NR_MUL_WAIT;
      end

      NR_MUL_WAIT: begin
        if (mulDone) begin
          nextState = (itersDone) ? NR_DONE : NR_FMAD_KICK;
        end

        else begin
          nextState = NR_MUL_WAIT;
        end
      end

      NR_DONE: begin
        nrrDone = 1;
        nextState = NR_DONE;
      end
    endcase
  end
endmodule : nrrFSM

module newtonRaphsonReciprocal
  #(parameter int FRACW = 8,
    parameter int WIDTH = FRACW + 2,
    parameter int OUTWIDTH = 2 * WIDTH,
    parameter int ITERS = $clog2(WIDTH))
  (input  logic [WIDTH - 1:0] nrrIn,
   input  logic               start, reset, clock,
   output logic [WIDTH - 1:0] nrrOut,
   output logic               nrrDone);

  localparam logic [WIDTH - 1:0] ONE = WIDTH'(1 << FRACW);
  localparam logic [WIDTH - 1:0] TWO = WIDTH'(2 << FRACW);

  int unsigned iterCounter;

  // Next iteration.
  logic [OUTWIDTH - 1:0] nextOut;

  // FMAD output.
  logic [OUTWIDTH - 1:0] fmadOut;

  // Multiplication inputs.
  logic [WIDTH - 1:0] mulIn1;
  logic [WIDTH - 1:0] mulIn2;

  logic itersDone;
  assign itersDone = (iterCounter == ITERS);

  logic compEn, fmadDone, mulDone;
  logic fmadStart, mulStart;

  always_ff @(posedge clock) begin
    if (start) begin
      // TODO: Add LUT for initial guess.
      nrrOut <= ONE;
      iterCounter <= 0;
    end

    else if (mulDone) begin
      nrrOut <= (nextOut >> FRACW);
      iterCounter <= (iterCounter + 1);
    end
  end

  fmad #(.WIDTH(WIDTH)) nrrFMAD(.fmadMulIn1(nrrIn), .fmadMulIn2(nrrOut),
                                .fmadAddIn(TWO), .start(fmadStart),
                                .clock, .reset, .sub(1'b0), .negate(1'b1),
                                .fmadOut, .fmadDone);

  assign mulIn1 = nrrOut;
  assign mulIn2 = (fmadOut >> FRACW);

  radix16Mult #(.WIDTH(WIDTH)) multiplier(.mulIn1, .mulIn2, .clock, .reset, .start(mulStart),
                                          .mulOut(nextOut), .done(mulDone));

  nrrFSM FSM(.*);
endmodule : newtonRaphsonReciprocal
`endif
