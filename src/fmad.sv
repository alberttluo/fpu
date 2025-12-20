/*
* fmad.sv: Implementation of a fused multiply add for integers.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef sv_FMAD
`define sv_FMAD

`include "constants.sv"

typedef enum logic [1:0] {
  FMAD_WAIT,
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
   output logic [OUTWIDTH - 1:0] fmadOut,
   output logic                  fmadDone);

  logic mulStart, mulDone;
  logic [OUTWIDTH - 1:0] mulOut;
  logic fmadAddEn;

  always_ff @(posedge clock) begin
    if (reset) begin
      fmadOut <= {WIDTH{1'b0}};
      mulStart <= 1'b0;
    end
    
    else if (start) begin
      mulStart <= 1'b1;
    end

    else if (fmadDone) begin
      fmadOut <= mulOut + {{WIDTH{1'b0}}, fmadAddIn};
    end
  end

  fpuMultiplier16 multiplier(.mulIn1(fmadMulIn1), .mulIn2(fmadMulIn2),
                             .start(mulStart), .clock, .reset, .mulOut,
                             .done(mulDone));

  fmadFSM FSM(.*);
endmodule : fmad

module fmadFSM
  (input  logic start, mulDone, clock, reset,
   output logic fmadAddEn, fmadDone);

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
    unique case (currState)
      FMAD_WAIT: nextState = (start) ? FMAD_MUL : FMAD_WAIT;

      FMAD_MUL: nextState = (mulDone) ? FMAD_DONE : FMAD_ADD;

      // Allows one clock cycle for addition.
      FMAD_ADD: nextState = FMAD_DONE;

      FMAD_DONE: nextState = FMAD_DONE;
    endcase
  end

  assign fmadDone = (currState == FMAD_DONE);
  assign fmadAddEn = (currState == FMAD_ADD);
endmodule : fmadFSM

`endif
