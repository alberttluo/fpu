/*
* fmad.sv: Implementation of a fused multiply add for integers.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef sv_FMAD
`define sv_FMAD

`include "constants.sv"

typedef enum logic [2:0] {
  FMAD_WAIT,
  FMAD_MUL_KICK,
  FMAD_MUL,
  FMAD_ADD,
  FMAD_DONE
} fmadState_t;

module fmad
  #(parameter int WIDTH = `FP16_FRACW + 1,
    parameter int OUTWIDTH = 2 * WIDTH)
  (input  logic [WIDTH - 1:0]    fmadMulIn1, fmadMulIn2,
                                 fmadAddIn,
   input  logic                  start, clock, reset,
   input  logic                  sub, negate,
   output logic [OUTWIDTH - 1:0] fmadOut,
   output logic                  fmadDone);

  logic mulStart, mulDone;
  logic [OUTWIDTH - 1:0] mulOut;
  logic fmadAddEn;

  // Latched inputs.
  logic [WIDTH - 1:0] latchedM1;
  logic [WIDTH - 1:0] latchedM2;
  logic [WIDTH - 1:0] latchedA;

  always_ff @(posedge clock) begin
    if (start) begin
      fmadOut <= {WIDTH{1'b0}};
      latchedM1 <= fmadMulIn1;
      latchedM2 <= fmadMulIn2;
      latchedA <= fmadAddIn;
    end

    else if (fmadAddEn) begin
      fmadOut <= (sub) ? ((negate) ? -mulOut : mulOut) - {{WIDTH{1'b0}}, latchedA} :
                         ((negate) ? -mulOut : mulOut) + {{WIDTH{1'b0}}, latchedA};
    end
  end

  radix16Mult #(.WIDTH(WIDTH)) multiplier(.mulIn1(latchedM1), .mulIn2(latchedM2),
                                          .start(mulStart), .clock, .reset, .mulOut,
                                          .done(mulDone));

  fmadFSM FSM(.*);
endmodule : fmad

module fmadFSM
  (input  logic start, mulDone, clock, reset,
   output logic mulStart, fmadAddEn, fmadDone);

  fmadState_t currState, nextState;

  always_ff @(posedge clock, posedge reset) begin
    if (reset) begin
      currState <= FMAD_WAIT;
    end
    else begin
      currState <= nextState;
    end
  end

  always_comb begin
    mulStart = 1'b0;
    fmadAddEn = 1'b0;
    fmadDone = 1'b0;
    unique case (currState)
      FMAD_WAIT: nextState = (start) ? FMAD_MUL_KICK : FMAD_WAIT;

      FMAD_MUL_KICK: begin
        nextState = FMAD_MUL;
        mulStart = 1'b1;
      end

      FMAD_MUL: begin
        nextState = (mulDone) ? FMAD_ADD : FMAD_MUL;
      end

      // Allows one clock cycle for addition.
      FMAD_ADD: begin
        nextState = FMAD_DONE;
        fmadAddEn = 1'b1;
      end

      FMAD_DONE: begin
        nextState = FMAD_DONE;
        fmadDone = 1'b1;
      end
    endcase
  end
endmodule : fmadFSM

`endif
