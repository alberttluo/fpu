/*
* fpu_mul.sv: A floating point multiplication coprocessor.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "multiplier.sv"
`include "library.sv"
`include "fpu_lib.sv"

typedef enum logic [1:0] {
  FPMUL_WAIT,
  FPMUL_SIGCOMP,
  FPMUL_DONE
} fpuMulState_t;

module fpuMul
  #(parameter type FP_T = fp16_t,
    parameter int FRACW = 10,
    parameter int EXPW = 5,
    parameter int EXP_MAX = (1 << EXPW) - 1,
    parameter int BIAS = 15)
  (input  FP_T           fpuIn1, fpuIn2,
   input  logic          clock, reset, start,
   output FP_T           fpuOut,
   output logic          done,
   output condCode_t     condCodes,
   output opStatusFlag_t opStatusFlags);

  // Significand multiplication signals.
  logic [1:0] sigMulOutInt;
  logic [2 * FRACW - 1:0] sigMulOutFrac;
  logic sigMulDone;
  logic [FRACW:0] sigMulIn1;
  logic [FRACW:0] sigMulIn2;

  // Output sign determined solely by input signs.
  logic outSign;

  // Sticky bit for rounding.
  logic sticky;

  // Normalization fields.
  logic [EXPW - 1:0] unnormExp;

  // Explicit condition codes.
  logic Z, C, N, V;
  assign condCodes = {Z, C, N, V};

  assign outSign = fpuIn1.sign ^ fpuIn2.sign;

  // Explicit OF flag (no need to be set in normalizer).
  logic OFin;
  logic expCarry;
  logic denorm;
  assign {expCarry, unnormExp} = fpuIn1.exp + fpuIn2.exp - BIAS;

  // Ensure that underflow from the above computation does not signal OF.
  assign denorm = ((fpuIn1.exp + fpuIn2.exp) <= {expCarry, unnormExp});
  assign OFin = ((expCarry & ~denorm) | ~denorm & (unnormExp == {EXPW{1'b1}} | unnormExp > EXP_MAX));

  // Prepend implicit 1 or 0 based on exponent.
  assign sigMulIn1 = (fpuIn1.exp == '0) ? {1'b0, fpuIn1.frac} : {1'b1, fpuIn1.frac};
  assign sigMulIn2 = (fpuIn2.exp == '0) ? {1'b0, fpuIn2.frac} : {1'b1, fpuIn2.frac};

  // Sequential multiplier to multiply significands.
  radix16Mult #(.FRACW(FRACW)) sigMultiplier(.mulIn1(sigMulIn1), .mulIn2(sigMulIn2), .start,
                                             .clock, .reset, .mulOut({sigMulOutInt, sigMulOutFrac}),
                                             .done(sigMulDone));

  assign sticky = sigMulOutFrac[FRACW - 1:0] != 0;
  fpuNormalizer #(.FP_T(FP_T), .FRACW(FRACW), .EXPW(EXPW), .EXP_MAX(EXP_MAX), .PFW(2 * FRACW))
                mulNormalizer(.unnormSign(outSign), .unnormInt(sigMulOutInt),
                              .unnormFrac(sigMulOutFrac),
                              .unnormExp(denorm ? EXPW'(0) : unnormExp),
                              .denormDiff(EXPW'(BIAS) - (fpuIn1.exp + fpuIn2.exp)),
                              .sticky,
                              .OFin, .div(1'b0), .normOut(fpuOut),
                              .opStatusFlags);

  // TODO: Fix C and V.
  assign Z = (fpuOut == '0);
  assign C = 1'b0;
  assign N = fpuOut.sign;
  assign V = 1'b0;
  fpuMulFSM FSM(.*);
endmodule : fpuMul

module fpuMulFSM
  (input  logic start, sigMulDone,
   input  logic clock, reset,
   output logic done);

  fpuMulState_t currState, nextState;

  always_ff @(posedge clock, posedge reset) begin
    if (reset) begin
      currState <= FPMUL_WAIT;
    end

    else begin
      currState <= nextState;
    end
  end

  always_comb begin
    unique case (currState)
      FPMUL_WAIT: nextState = (start) ? FPMUL_SIGCOMP : FPMUL_WAIT;

      FPMUL_SIGCOMP: nextState = (sigMulDone) ? FPMUL_DONE : FPMUL_SIGCOMP;

      FPMUL_DONE: nextState = FPMUL_DONE;
    endcase
  end

  assign done = (currState == FPMUL_DONE);
endmodule : fpuMulFSM
