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

module fpuMul16
  (input  fp16_t         fpuIn1, fpuIn2,
   input  logic          clock, reset, start,
   output fp16_t         fpuOut,
   output logic          done,
   output condCode_t     condCodes,
   output opStatusFlag_t opStatusFlags);

  // Significand multiplication signals.
  logic [1:0] sigMulOutInt;
  logic [2 * `FP16_FRACW - 1:0] sigMulOutFrac;
  logic sigMulDone;
  logic [`FP16_FRACW:0] sigMulIn1;
  logic [`FP16_FRACW:0] sigMulIn2;

  // Output sign determined solely by input signs.
  logic outSign;

  // Sticky bit for rounding.
  logic sticky;

  // Normalization fields.
  logic [`FP16_EXPW - 1:0] unnormExp;

  // Explicit condition codes.
  logic Z, C, N, V;
  assign condCodes = {Z, C, N, V};

  assign outSign = fpuIn1.sign ^ fpuIn2.sign;

  // Explicit OF flag (no need to be set in normalizer).
  logic OFin;
  logic expCarry;
  logic denorm;
  assign {expCarry, unnormExp} = fpuIn1.exp + fpuIn2.exp - `FP16_BIAS;

  // Ensure that underflow from the above computation does not signal OF.
  assign denorm = ((fpuIn1.exp + fpuIn2.exp) <= {expCarry, unnormExp});
  assign OFin = ((expCarry & ~denorm) | ~denorm & (unnormExp == {`FP16_EXPW{'1}} | unnormExp > `FP16_EXP_MAX));

  // Prepend implicit 1 or 0 based on exponent.
  assign sigMulIn1 = (fpuIn1.exp == '0) ? {1'b0, fpuIn1.frac} : {1'b1, fpuIn1.frac};
  assign sigMulIn2 = (fpuIn2.exp == '0) ? {1'b0, fpuIn2.frac} : {1'b1, fpuIn2.frac};

  // Sequential multiplier to multiply significands.
  fpuMultiplier sigMultiplier(.mulIn1(sigMulIn1), .mulIn2(sigMulIn2), .start,
                              .clock, .reset, .mulOut({sigMulOutInt, sigMulOutFrac}),
                              .done(sigMulDone));

  assign sticky = sigMulOutFrac[`FP16_FRACW - 1:0] != `FP16_FRACW'd0;
  fpuNormalizer16 #(.PFW(2 * `FP16_FRACW)) mulNormalizer(.unnormSign(outSign), .unnormInt(sigMulOutInt),
                                                         .unnormFrac(sigMulOutFrac),
                                                         .unnormExp(denorm ? {`FP16_EXPW'd0} : unnormExp),
                                                         .denormDiff(`FP16_BIAS - (fpuIn1.exp + fpuIn2.exp)),
                                                         .sticky,
                                                         .OFin, .normOut(fpuOut),
                                                         .opStatusFlags);

  // TODO: Fix C and V.
  assign Z = (fpuOut == '0);
  assign C = 1'b0;
  assign N = fpuOut.sign;
  assign V = 1'b0;
  fpuMulFSM FSM(.*);
endmodule : fpuMul16

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
