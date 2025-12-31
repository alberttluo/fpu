/*
* lib.sv: A library file for all floating point operations.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef sv_FPULIB
`define sv_FPULIB

`include "constants.sv"

/*
* Aligns binary points for addition/subtraction of two floating
* point inputs.
*/
module fpuAddSubAligner
  #(parameter type FP_T  = fp16_t,
    parameter int  FRACW = 10,
    parameter int  EXPW  = 5)
  (input  FP_T                largeNum, smallNum,
   output FP_T                alignedSmallNum,
   output logic [FRACW - 1:0] shiftedOut,
   output logic               sticky);

  logic [EXPW - 1:0] expDiff;

  // Significand with explicit leading integer (2 bits).
  logic [FRACW + 1:0] extFrac;

  always_comb begin
    // Exponent is 1 if denormalized -- not zero.
    expDiff = (largeNum.exp == EXPW'(0) ? EXPW'(1) : largeNum.exp) - (smallNum.exp == EXPW'(0) ? EXPW'(1) : smallNum.exp);

    // Effective sign -- flip if subtraction so we can always add.
    alignedSmallNum.sign = smallNum.sign;

    {extFrac, shiftedOut} = {smallNum.exp != '0 ? 1'b1 : 1'b0, smallNum.frac, FRACW'(0)} >> expDiff;

    // TODO: Deal with NaNs.
    alignedSmallNum.exp = largeNum.exp;
    alignedSmallNum.frac = extFrac[FRACW - 1:0];

    sticky = (shiftedOut != FRACW'(0));
  end
endmodule : fpuAddSubAligner

// Basic leading zeros counter (+ 1) for shift amount.
// TODO: Optimize.
module fpuLZC
  #(parameter int WIDTH = 16,
              int OUTWIDTH = $clog2(WIDTH + 1))
  (input  logic [WIDTH - 1:0]    lzcIn,
   output logic [OUTWIDTH - 1:0] lzcOut);

  always_comb begin
    lzcOut = WIDTH;
    for (int i = WIDTH - 1; i >= 0; i--) begin
      if (lzcIn[i] && lzcOut == WIDTH)
        lzcOut = WIDTH - i;
    end
  end
endmodule : fpuLZC

module fpuTZC
  #(parameter int WIDTH = 16,
              int OUTWIDTH = $clog2(WIDTH + 1))
  (input  logic [WIDTH - 1:0]    tzcIn,
   output logic [OUTWIDTH - 1:0] tzcOut);

  always_comb begin
    tzcOut = 0;
    for (int i = 0; i < WIDTH; i++) begin
      if (tzcIn[i] && tzcOut == 0)
        tzcOut = i;
    end
  end
endmodule : fpuTZC

/*
* Normalizer for addition, subtaction, and multiplication.
* Currently only supports half-precision.
*/
module fpuNormalizer
  // Paramterized by pure fractional width before truncation and not including
  // the leading integer part.
  #(parameter type FP_T = fp16_t,
    parameter int FRACW = 10,
    parameter int EXPW = 5,
    parameter int EXP_MAX = 30,
    parameter int PFW = 10)
  (input  logic                     unnormSign,
   input  logic [1:0]               unnormInt,
   input  logic [PFW - 1:0]         unnormFrac,
   input  logic [EXPW - 1:0]        unnormExp,
   input  logic [EXPW - 1:0]        denormDiff,
   input  logic                     sticky,
   input  logic                     OFin,
   input  logic                     div,
   output fp16_t                    normOut,
   output opStatusFlag_t            opStatusFlags);

  // Leading zeros count (not including carry out).
  // Technically, this is leading zeros count + 1, but we store it for shifting
  // purposes.
  logic [$clog2(PFW + 1) - 1:0] lzc;

  // Extended significand with explicit 2 bits leading integer.
  logic [PFW + 1:0] explicitSig;

  // Mantissa after rounding.
  logic [FRACW - 1:0] roundedFrac;

  // Explicit op status flags.
  logic OF, UF, NX;
  logic preRoundOF;
  logic roundNormOF;
  assign OF = (preRoundOF | roundNormOF | OFin);
  assign opStatusFlags = {OF, UF, NX};

  // Rounded exponent (may have to add 1 due to fractional rounding).
  logic [EXPW - 1:0] roundedExp;
  logic [EXPW - 1:0] preRoundExp;

  // Denormalized detection.
  logic denormalized;
  assign denormalized = ((unnormExp == EXPW'(0)) & ~OFin);

  // Post denormalized mantissa.
  logic [PFW - 1:0] postDenormFrac;

  // Denormalized shift amount.
  logic [FRACW - 1:0] denormShiftAmount;

  // Rounding bits for both normal and denormal formats.
  logic guard, round;
  logic denormGuard, denormRound;

  logic [PFW - 1:0] roundedPostDenormFrac;
  assign roundedPostDenormFrac = postDenormFrac;

  // Shifted out integer part after denormalization.
  logic [1:0] postDenormInt;

  // Denorm diff may be negative.
  logic [EXPW - 1:0] absDenormDiff;

  // Calcualte LZC (shifts).
  fpuLZC #(.WIDTH(PFW)) fpuMulLZC(.lzcIn(unnormFrac), .lzcOut(lzc));

  // Check if biased exponent is 0 (denormalized), so shift binary point left 1.
  always_comb begin
    normOut.exp = OF ? {FRACW{'1}} : roundedExp;
    postDenormInt = explicitSig[PFW + 1:PFW];

    if (denormalized) begin
      normOut.frac = OF ? FRACW'(0) :
                           roundedPostDenormFrac[PFW - 1:PFW - FRACW] + (denormRound & (denormGuard | sticky));

      if (denormDiff[EXPW - 1]) begin
        {postDenormInt, postDenormFrac} = (div) ? explicitSig >> denormShiftAmount : explicitSig << denormShiftAmount;
      end

      else begin
        {postDenormInt, postDenormFrac} = (div) ? explicitSig << denormShiftAmount : explicitSig >> denormShiftAmount;
      end
    end

    else begin
      postDenormFrac = (div) ? explicitSig[PFW - 1:PFW - FRACW] : explicitSig[PFW - FRACW:0];
      normOut.frac = OF ? FRACW'(0) : roundedFrac;
    end
  end

  // Normalization logic.
  always_comb begin
    // Signs always remain the same.
    normOut.sign = unnormSign;

    // Default guard bit is the top bit in the extended part.
    guard = explicitSig[PFW - FRACW];
    round = explicitSig[PFW - FRACW - 1];
    denormGuard = postDenormFrac[PFW - FRACW];
    denormRound = postDenormFrac[PFW - FRACW - 1];
    preRoundOF = 1'b0;
    absDenormDiff = (denormDiff[EXPW - 1]) ? ~(denormDiff) + EXPW'(1) : denormDiff;
    denormShiftAmount = (absDenormDiff + 1);

    if (unnormInt > 2'd1) begin
      preRoundExp = (denormalized) ? unnormExp : unnormExp + EXPW'(1);

      if (preRoundExp > EXP_MAX) begin
        preRoundOF = 1'b1;
      end

      explicitSig = {unnormInt, unnormFrac} >> 1;
      denormShiftAmount--;

      guard = unnormFrac[PFW - FRACW + 1];
      round = unnormFrac[PFW - FRACW];
    end

    else if (unnormInt == 2'b0) begin
      if (lzc <= unnormExp) begin
        preRoundExp = unnormExp - lzc;
        explicitSig = {unnormInt, unnormFrac} << lzc;
      end

      else begin
        preRoundExp = 0;
        explicitSig = {unnormInt, unnormFrac};
      end
    end

    else begin
      preRoundExp = unnormExp;
      explicitSig = {unnormInt, unnormFrac};
    end
  end

  // Rounding logic.
  always_comb begin
    roundedExp = (denormalized && (postDenormInt != 2'd0)) ?
                 EXPW'(1) : preRoundExp;

    roundNormOF = 1'b0;

    // Round up case.
    if (round & (sticky | guard)) begin
      roundedFrac = explicitSig[PFW - 1:PFW - FRACW] + FRACW'(1);

      // Overflow to exponent.
      if (roundedFrac == '0) begin
        // TODO: NaNs and infinites.
        roundedExp = preRoundExp + EXPW'(1);

        if (roundedExp == 0 || roundedExp > EXP_MAX) begin
          roundNormOF = 1;
        end
      end
    end

    // Round to even case.
    else if (guard & round & ~sticky) begin
      roundedFrac = explicitSig[PFW - 1:PFW - FRACW] & 16'hFFFD;
    end

    // Otherwise do nothing.
    else begin
      roundedFrac = explicitSig[PFW - 1:PFW - FRACW];
    end
  end

  // Result is inexact if any shifted out bits are 1.
  assign NX = (sticky | round);
  assign UF = ~OF && (roundedExp == 0 && roundedFrac != 0);
endmodule : fpuNormalizer

/* Sorts two inputs such that the larger magnitude number is stored in largeNum,
*  and the smaller in smallNum.
*/
module fpuAddSubSorter
  #(parameter type FP_T = fp16_t)
  (input  FP_T fpuIn1, fpuIn2,
   output FP_T largeNum, smallNum);

  assign {largeNum, smallNum} = ({fpuIn1.exp, fpuIn1.frac} > {fpuIn2.exp, fpuIn2.frac}) ?
                                {fpuIn1, fpuIn2} : {fpuIn2, fpuIn1};
endmodule : fpuAddSubSorter

/*
* Checks that an input is either infinity or NaN.
*/
module fpuIsSpecialValue
  #(parameter type FP_T = fp16_t,
    parameter int FRACW = 10,
    parameter int EXPW = 5)
  (input  FP_T  fpuIn,
   output logic inf, nan);

  always_comb begin
    inf = 1'b0;
    nan = 1'b0;
    if (fpuIn.exp == {EXPW{1'b1}}) begin
      if (fpuIn.frac == {FRACW{1'b0}}) begin
        inf = 1'b1;
      end

      else begin
        nan = 1'b1;
      end
    end
  end
endmodule : fpuIsSpecialValue
`endif
