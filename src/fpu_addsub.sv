/*
* fpu_addsub.sv: Performs FPU addition/subtraction, given both inputs broken
* down into their sign, exponent, and mantissa parts. (done by FPU top module).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/
`default_nettype none

`include "constants.sv"
`include "fpu_lib.sv"

module fpuAddSub16
  (input  logic          sub,
   input  fp16_t         fpuIn1, fpuIn2,
   output fp16_t         fpuOut,
   output condCode_t     condCodes,
   output opStatusFlag_t opStatusFlags);

  // Explicit condition codes.
  logic Z, C, N, V;
  assign condCodes = {Z, C, N, V};

  // Sticky bit for rounding.
  logic sticky;

  // Effective sign for fpuIn2 if subtraction.
  logic effS1;
  logic effS2;
  assign effS1 = fpuIn1.sign;
  assign effS2 = fpuIn2.sign ^ sub;

  // Sort the numbers so that the larger magnitude number is on top.
  fp16_t largeNum;
  fp16_t smallNum;
  fpuAddSubSorter sorter(.*);

  // Effective signs after sorting.
  logic effSignLarge, effSignSmall;
  always_comb begin
    if (largeNum == fpuIn1) begin
      effSignLarge = effS1;
      effSignSmall = effS2;
    end

    else begin
      effSignLarge = effS2;
      effSignSmall = effS1;
    end
  end

  // Bits that get shifted out from the aligner.
  logic [`FP16_FRACW - 1:0] shiftedOut;

  // Align binary points.
  fp16_t alignedSmallNum;
  fpuAddSubAligner aligner(.*);

  // Add significands (keep the shifted out bits from aligner).
  logic [2 * `FP16_FRACW - 1:0] fracSum;
  logic [2 * `FP16_FRACW:0] extLargeFrac;
  logic [2 * `FP16_FRACW:0] extSmallFrac;

  // Fields to build the unnormalized input.
  logic [1:0] intPart;

  assign extLargeFrac = (largeNum.exp == '0) ? {1'b0, largeNum.frac, `FP16_FRACW'd0} :
                                               {1'b1, largeNum.frac, `FP16_FRACW'd0};
  assign extSmallFrac = {1'b0, alignedSmallNum.frac, shiftedOut};

  assign {intPart, fracSum} = (effSignLarge == effSignSmall) ?
                              (extLargeFrac + extSmallFrac) :
                              (extLargeFrac - extSmallFrac);

  // Normalize floating point fields.
  fp16_t normalizedOut;

  // Pack the fractional part along with largeNum fields to get unnormalized
  // value.
  fpuNormalizer16 #(.PFW(2 * `FP16_FRACW)) normalizer(.unnormSign(effSignLarge), .unnormInt(intPart),  
                                                      .unnormFrac(fracSum),
                                                      .unnormExp(largeNum.exp), .sticky, .normOut(normalizedOut),
                                                      .opStatusFlags);

  // Set condition codes.
  assign Z = (normalizedOut == '0);
  assign C = 1'b0;
  assign N = normalizedOut.sign;
  assign V = 1'b0;

  assign fpuOut = normalizedOut;
endmodule : fpuAddSub16
