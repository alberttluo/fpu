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
  localparam logic[EXPW - 1:0] BIAS = (EXPW == 5) ? 10'd15 : ((EXPW == 8) ? 23'd127 : 52'd1023);
  localparam int unsigned EXP_MAX = (1 << EXPW) - 2;

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
  logic [2 * FRACW - 1:0] adjustedDividend;
  logic [2 * FRACW - 1:0] adjustedDivisor;
  logic [2 * FRACW - 1:0] significandDivOut;
  logic [2 * FRACW - 1:0] divOutFrac;
  logic sigDivDone;

  assign adjustedDividend = {dividendSig, {(FRACW-1){1'b0}}};
  assign adjustedDivisor = (divisorSig >> divisorTZC);

  fpuDivider #(.WIDTH(2 * FRACW)) divider(.divIn1(adjustedDividend),
                                          .divIn2(adjustedDivisor),
                                          .start, .clock, .reset,
                                          .divOut(significandDivOut),
                                          .divRem(),
                                          .done(sigDivDone));

  // Normalize and round output.
  logic outSign;
  assign outSign = fpuIn1.sign ^ fpuIn2.sign;

  logic [1:0] unnormInt;
  logic [2 * FRACW - 1:0] unnormFrac;
  logic expCarry;
  logic denorm;
  logic [EXPW - 1:0] unnormExp;

  logic OFin;

  // Keep at 64-bit width to ensure overflow can never happen.
  logic [63:0] intShiftAmt;
  assign intShiftAmt = (FRACW + divisorTZC - 1);

  assign unnormInt = significandDivOut >> intShiftAmt;

  // Form the unnormalized fraction by taking the bits after the decimal point.
  assign divOutFrac = significandDivOut & ((1 << (2 * FRACW - (divisorTZC + 1))) - 1);
  assign unnormFrac = divOutFrac << (FRACW - divisorTZC + 1);

  assign {expCarry, unnormExp} = fpuIn1.exp - fpuIn2.exp + BIAS;

  // Ensure that underflow from the above computation does not signal OF.
  assign denorm = ((fpuIn1.exp + fpuIn2.exp) <= {expCarry, unnormExp});
  assign OFin = ((expCarry & ~denorm) | ~denorm & (unnormExp == {EXPW{1'b1}} | unnormExp > EXP_MAX));
  fpuNormalizer16 #(.PFW(2 * FRACW)) divNormalizer(.unnormSign(outSign),
                                                   .unnormInt,
                                                   .unnormFrac,
                                                   .unnormExp(denorm ? EXPW'(0) : unnormExp),
                                                   .denormDiff(BIAS + (fpuIn1.exp - fpuIn2.exp)),
                                                   .sticky(1'b0),
                                                   .OFin, .div(1'b1),
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
