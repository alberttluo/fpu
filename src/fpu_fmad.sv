/*
* fpu_fmad.sv: FMAD for floating point operations. This is not the traditional
* FMAD, as we do normalization before and after the multiplication/addition
* steps.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

typedef enum logic [2:0] {
  FPFMAD_WAIT,
  FPFMAD_MUL_KICK,
  FPFMAD_MUL_WAIT,
  FPFMAD_DONE
} fpuFMADState_t;

module fpuFMAD
  #(parameter type FP_T = fp16_t,
    parameter int FRACW = 10,
    parameter int EXPW = 5,
    parameter int EXP_MAX = (1 << EXPW) - 1,
    parameter int BIAS = 15)
  (input  FP_T           fpuIn1, fpuIn2, fpuIn3,
   input  logic          clock, reset, start,
   input  logic          sub, negate,
   output FP_T           fpuOut,
   output logic          done,
   output condCode_t     condCodes,
   output opStatusFlag_t opStatusFlags);

  // Multiplication signals.
  logic mulStart, mulDone;
  FP_T mulOut;

  FP_T addOut;

  fpuMul #(.FP_T(FP_T), .FRACW(FRACW), .EXPW(EXPW), .EXP_MAX(EXP_MAX), .BIAS(BIAS))
    multiplier(.fpuIn1, .fpuIn2, .clock, .reset, .start(mulStart), .fpuOut(mulOut),
               .done(mulDone), .condCodes(), .opStatusFlags());

  fpuAddSub #(.FP_T(FP_T), .FRACW(FRACW), .EXPW(EXPW), .EXP_MAX(EXP_MAX), .BIAS(BIAS))
    adder(.sub, .fpuIn1(mulOut), .fpuIn2(fpuIn3), .fpuOut(addOut), .condCodes, .opStatusFlags);

  assign fpuOut = {negate ^ addOut.sign, addOut.exp, addOut.frac};

  fpuFMADFSM FSM(.*);
endmodule : fpuFMAD

module fpuFMADFSM
  (input  logic clock, reset, start, mulDone,
   output logic mulStart, done);

  fpuFMADState_t currState, nextState;

  always_ff @(posedge clock, posedge reset) begin
    if (reset) begin
      currState <= FPFMAD_WAIT;
    end

    else begin
      currState <= nextState;
    end
  end

  always_comb begin
    mulStart = 0;
    done = 0;
    unique case (currState)
      FPFMAD_WAIT: nextState = (start) ? FPFMAD_MUL_KICK : FPFMAD_WAIT;

      FPFMAD_MUL_KICK: begin
        mulStart = 1;
        nextState = FPFMAD_MUL_WAIT;
      end

      FPFMAD_MUL_WAIT: begin
        nextState = (mulDone) ? FPFMAD_DONE : FPFMAD_MUL_WAIT;
      end

      FPFMAD_DONE: begin
        done = 1;
        nextState = FPFMAD_DONE;
    end
    endcase
  end
endmodule : fpuFMADFSM
