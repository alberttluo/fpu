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
  (input  fp16_t                    largeNum, smallNum,
   output fp16_t                    alignedSmallNum,
   output logic [`FP16_FRACW - 1:0] shiftedOut,
   output logic                     sticky);

  logic [`FP16_EXPW - 1:0] expDiff;

  // Significand with explicit leading integer (2 bits).
  logic [`FP16_FRACW + 1:0] extFrac;

  always_comb begin
    expDiff = largeNum.exp - smallNum.exp;

    // Effective sign -- flip if subtraction so we can always add.
    alignedSmallNum.sign = smallNum.sign;

    {extFrac, shiftedOut} = {smallNum.exp != '0 ? 1'b1 : 1'b0, smallNum.frac, `FP16_FRACW'd0} >> expDiff;

    // TODO: Deal with NaNs.
    alignedSmallNum.exp = largeNum.exp;
    alignedSmallNum.frac = extFrac[`FP16_FRACW - 1:0];

    sticky = (shiftedOut != '0);
  end
endmodule : fpuAddSubAligner

// Basic leading zeros counter (+ 1) for shift amount.
// TODO: Optimize.
module fpuLZC
  #(parameter int WIDTH = 16,
              int OUTWIDTH = $clog2(WIDTH + 1))
  (input  logic [WIDTH - 1:0]             lzcIn,
   output logic [OUTWIDTH - 1:0] lzcOut);

  always_comb begin
    lzcOut = WIDTH;
    for (int i = WIDTH - 1; i >= 0; i--) begin
      if (lzcIn[i] && lzcOut == WIDTH)
        lzcOut = WIDTH - i;
    end
  end
endmodule : fpuLZC

/*
* Normalizer for addition, subtaction, and multiplication.
* Currently only supports half-precision.
*/
module fpuNormalizer16
  // Paramterized by pure fractional width before truncation and not including
  // the leading integer part.
  #(parameter int PFW = 10)
  (input  logic                    unnormSign,
   input  logic [1:0]              unnormInt,
   input  logic [PFW - 1:0]        unnormFrac,
   input  logic [`FP16_EXPW - 1:0] unnormExp,
   input  logic                    sticky,
   output fp16_t                   normOut,
   output statusFlag_t             statusFlags);

  // Leading zeros count (not including carry out).
  // Technically, this is leading zeros count + 1, but we store it for shifting
  // purposes.
  logic [$clog2(PFW + 1) - 1:0] lzc;

  // Extended significand with explicit 2 bits leading integer.
  logic [PFW + 1:0] explicitSig;

  // Mantissa after rounding.
  logic [`FP16_FRACW - 1:0] roundedFrac;

  // Explicit status flags.
  logic NV, DZ, OF, UF, NX;
  assign statusFlags = {NV, DZ, OF, UF, NX};

  // Rounded exponent (may have to add 1 due to fractional rounding).
  logic [`FP16_EXPW - 1:0] roundedExp;
  logic [`FP16_EXPW - 1:0] preRoundExp;

  logic guard, round, stickyNorm;

  // Calcualte LZC (shifts).
  fpuLZC #(.WIDTH(PFW)) fpuMulLZC(.lzcIn(unnormFrac), .lzcOut(lzc));

  // Normalization logic.
  always_comb begin
    // Signs always remain the same.
    normOut.sign = unnormSign;

    // Default guard bit is the top bit in the extended part.
    guard = 1'b0;
    round = 1'b0;

    if (unnormInt > 2'd1) begin
      preRoundExp = unnormExp + `FP16_EXPW'd1;
      explicitSig = {unnormInt, unnormFrac} >> 1;

      guard = unnormFrac[PFW - `FP16_FRACW];

      // Multiplication case.
      if (PFW > `FP16_FRACW)
        round = unnormFrac[PFW - `FP16_FRACW - 1];
    end

    else if (unnormInt == 2'b0) begin
      // TODO: Deal with overflow case.
      if (lzc <= unnormExp) begin
        preRoundExp = unnormExp - lzc;
        explicitSig = unnormFrac << lzc;
      end

      else begin
        normOut.sign = '0;
        preRoundExp = '0;
        explicitSig = '0;
      end
    end

    else begin
      preRoundExp = unnormExp;
      explicitSig = unnormFrac;
    end
  end

  // Rounding logic.
  always_comb begin
    roundedExp = preRoundExp;

    // Round up case.
    if (round & sticky) begin
      roundedFrac = explicitSig[PFW - 1:PFW - `FP16_FRACW] + `FP16_FRACW'd1;

      // Overflow to exponent.
      if (roundedFrac == '0) begin
        // TODO: NaNs and infinites.
        roundedExp = preRoundExp + `FP16_EXPW'd1;

        if (roundedExp == `FP16_EXPW'd0)
          OF = 1;
      end
    end

    // Round to even case.
    else if (guard & round & ~sticky)
      roundedFrac = explicitSig[PFW - 1:PFW - `FP16_FRACW] & 16'hFFFD;

    // Otherwise do nothing.
    else
      roundedFrac = explicitSig[PFW - 1:PFW - `FP16_FRACW];
  end

  // Result is inexact if any shifted out bits are 1.
  assign NX = (sticky | round);

  assign normOut.frac = roundedFrac;
  assign normOut.exp = roundedExp;
endmodule : fpuNormalizer16

/* Sorts two inputs such that the larger magnitude number is stored in largeNum,
*  and the smaller in smallNum.
*/
module fpuAddSubSorter
  (input  fp16_t fpuIn1, fpuIn2,
   output fp16_t largeNum, smallNum);

  assign {largeNum, smallNum} = ({fpuIn1.exp, fpuIn1.frac} > {fpuIn2.exp, fpuIn2.frac}) ?
                                {fpuIn1, fpuIn2} : {fpuIn2, fpuIn1};
endmodule : fpuAddSubSorter

/*
* Checks that an input is either infinity or NaN.
*/
module fpuIsSpecialValue
  (input  fp16_t fpuIn,
   output logic  inf, nan);

  always_comb begin
    inf = 1'b0;
    nan = 1'b0;
    if (fpuIn.exp == {`FP16_EXPW{'1}}) begin
      if (fpuIn.frac == {`FP16_FRACW{'0}}) begin
        inf = 1'b1;
      end

      else begin
        nan = 1'b1;
      end
    end
  end
endmodule : fpuIsSpecialValue
`endif
