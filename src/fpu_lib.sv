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
  (input  fp16_t largeNum, smallNum,
   output fp16_t alignedSmallNum,
   output logic  sticky);

  logic [`FP16_EXPW - 1:0] expDiff;

  // Significand with explicit leading integer (2 bits).
  logic [`FP16_FRACW + 1:0] extFrac;

  // The bits that were shifted out will be stored in the top bits.
  // Used for sticky bit calculations.
  logic [`FP16_FRACW - 1:0] shiftedOut;

  always_comb begin
    expDiff = largeNum.exp - smallNum.exp;

    // Effective sign -- flip if subtraction so we can always add.
    alignedSmallNum.sign = smallNum.sign;

    // Denormalized values have leading 0 instead of leading 1.
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
   output fp16_t                   normOut);

  // Leading zeros count (not including carry out).
  // Technically, this is leading zeros count + 1, but we store it for shifting
  // purposes.
  logic [$clog2(PFW + 1) - 1:0] lzc;

  // Extended significand with explicit 2 bits leading integer.
  logic [PFW + 1:0] explicitSig;

  // Mantissa after rounding.
  logic [`FP16_FRACW - 1:0] roundedFrac;

  // Rounding bits.
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
      normOut.exp = unnormExp + `FP16_EXPW'd1;
      explicitSig = {unnormInt, unnormFrac} >> 1;

      guard = unnormFrac[PFW - `FP16_FRACW];

      // Multiplication case.
      if (PFW > `FP16_FRACW)
        round = unnormFrac[PFW - `FP16_FRACW - 1];
    end

    else if (unnormInt == 2'b0) begin
      // TODO: Deal with overflow case.
      if (lzc <= unnormExp) begin
        normOut.exp = unnormExp - lzc;
        explicitSig = unnormFrac << lzc;
      end

      else begin
        normOut.sign = '0;
        normOut.exp = '0;
        explicitSig = '0;
      end
    end

    else begin
      normOut.exp = unnormExp;
      explicitSig = unnormFrac;
    end
  end

  // Rounding logic.
  // TODO: Deal with overflows into exponent.
  always_comb begin
    // Round up case.
    if (round & sticky)
      roundedFrac = explicitSig[PFW - 1:PFW - `FP16_FRACW] + `FP16_FRACW'd1;
    // Round to even case.
    else if (guard & round & ~sticky)
      roundedFrac = explicitSig[PFW - 1:PFW - `FP16_FRACW] & 16'hFFFD;
    // Otherwise do nothing.
    else
      roundedFrac = explicitSig[PFW - 1:PFW - `FP16_FRACW];
  end

  assign normOut.frac = roundedFrac;
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
`endif
