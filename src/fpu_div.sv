/*
* fpu_div.sv: A floating point division coprocessor.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "divider.sv"
`include "fpu_lib.sv"

typedef enum logic [1:0] {
  FPDIV_WAIT,
  FPDIV_SIGCOMP,
  FPDIV_DONE
} fpuDivState_t;

module fpuDiv
  #(parameter type FP_T = fp16_t)
  (input  FP_T           fpuIn1, fpuIn2,
   input  logic          clock, reset, start,
   output FP_T           fpuOut,
   output logic          done,
   output condCode_t     condCodes,
   output opStatusFlag_t opStatusFlags);

  localparam int EXPW = $bits(fpuIn1.exp);
  localparam int FRACW = $bits(fpuIn1.frac);
  localparam int BIAS = (EXPW == 5) ? 10'd15 : ((EXPW == 8) ? 23'd127 : 52'd1023);

  // Condition codes.
  logic Z, C, N, V;
  assign condCodes = {Z, C, N, V};

  // Significand division signals.
  logic [FRACW:0] dividendSig;
  logic [FRACW:0] divisorSig;
  assign dividendSig = {~(fpuIn1.exp == 0), fpuIn1.frac};
  assign divisorSig = {~(fpuIn2.exp == 0), fpuIn2.frac};

  // Left shift divisor significand until no more trailing zeros.
  logic [$clog2(FRACW + 1) - 1:0] divisorTZC;
  fpuTZC #(.WIDTH(FRACW)) tzc(.tzcIn(fpuIn2.frac), .tzcOut(divisorTZC));

  // Divide dividend significand by divisor fractional part.
  logic [2 * FRACW - 1:0] significandDivOut;
  logic [2 * FRACW - 1:0] significandDivRem;
  logic sigDivDone;

  fpuDivider #(.WIDTH(2 * FRACW)) divider(.divIn1({dividendSig, {(FRACW-1){1'b0}}}), .divIn2(divisorSig >> divisorTZC),
                                          .start, .clock, .reset,
                                          .divOut(significandDivOut),
                                          .divRem(significandDivRem),
                                          .done(sigDivDone));

  // Normalize and round output.
  logic outSign;
  assign outSign = fpuIn1.sign ^ fpuIn2.sign;
  fpuNormalizer16 #(.PFW(FRACW)) divNormalizer(.unnormSign(outSign),
                                                         .unnormInt(significandDivOut[FRACW + 1:FRACW]),
                                                         .unnormFrac(significandDivOut[FRACW - 1:0]),
                                                         .unnormExp(fpuIn1.exp - fpuIn2.exp + BIAS),
                                                         .denormDiff(0),
                                                         .sticky(1'b0),
                                                         .OFin(1'b0),
                                                         .normOut(fpuOut),
                                                         .opStatusFlags);

  assign Z = (fpuOut == 0);
  assign C = 1'b0;
  assign N = fpuOut.sign;
  assign V = 1'b0;

  fpuDivFSM FSM(.*);
endmodule : fpuDiv

module fpuDivFSM
  (input  logic start, sigDivDone,
   input  logic clock, reset,
   output logic done);

  fpuDivState_t currState, nextState;

  always_ff @(posedge clock, posedge reset) begin
    if (reset) begin
      currState <= FPDIV_WAIT;
    end

    else begin
      currState <= nextState;
    end
  end

  always_comb begin
    unique case (currState)
      FPDIV_WAIT: nextState = (start) ? FPDIV_SIGCOMP : FPDIV_WAIT;

      FPDIV_SIGCOMP: nextState = (sigDivDone) ? FPDIV_DONE : FPDIV_SIGCOMP;

      FPDIV_DONE: nextState = FPDIV_DONE;
    endcase
  end

  assign done = (currState == FPDIV_DONE);
endmodule : fpuDivFSM
