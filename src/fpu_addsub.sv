/*
* fpu_addsub.sv: Performs FPU addition/subtraction, given both inputs broken
* down into their sign, exponent, and mantissa parts. (done by FPU top module).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/
`default_nettype none

`include "constants.sv"

module fpuAddSub16
  (input  logic         sub,
   input  fp16_t        fpuIn1, fpuIn2,
   output fp16_t        fpuOut,
   output condCode_t    condCodes,
   // All internal signals for debugging (currently not used).
   output addSubDebug_t addSubView);

  // Explicit condition codes.
  logic Z, C, N, V;
  assign condCodes = {Z, C, N, V};

  // Sort the numbers so that the larger magnitude number is on top.
  fp16_t largeNum;
  fp16_t smallNum;
  fpuAddSubSorter sorter(.*);
  
  // Align binary points.
  fp16_t alignedSmallNum;
  fpuAddSubAligner aligner(.*);

  // Add significands.
  logic [`FP16_FRACW:0] extSigSum;
  logic [`FP16_FRACW:0] extLargeFrac;
  logic [`FP16_FRACW:0] extSmallFrac;

  assign extLargeFrac = (largeNum.exp == '0) ? {1'b0, largeNum.frac} :
                                               {1'b1, largeNum.frac};
  assign extSmallFrac = (smallNum.exp == '0) ? {1'b0, smallNum.frac} :
                                               {1'b1, smallNum.frac};
  assign extSigSum = (largeNum.sign == smallNum.sign) ? 
                     (extLargeFrac + extSmallFrac) :
                     (extLargeFrac - extSmallFrac);

  // Normalize floating point fields.
  fp16_t unnormalizedIn;
  fp16_t normalizedOut;

  // Pack the fractional part along with largeNum fields to get unnormalized
  // value.
  assign unnormalizedIn = {largeNum.sign, largeNum.exp, extSigSum[`FP16_FRACW - 1:0]};
  fpuNormalizer16 normalizer(.*);

  // Set condition codes.
  assign Z = (normalizedOut == '0);
  assign C = extSigSum[`FP16_FRACW];
  assign N = normalizedOut[15];
  assign V = (~sub & ~fpuIn1.sign & ~fpuIn2.sign & N) | (sub & fpuIn1.sign & fpuIn2.sign & ~N);

  assign fpuOut = normalizedOut;

  assign addSubView = {
     largeNum,
     smallNum,
     aligner.expDiff,
     alignedSmallNum,
     extSigSum,
     unnormalizedIn,
     normalizedOut,
     fpuOut
  };
endmodule : fpuAddSub16

// Sorts two inputs such that the larger magnitude number is stored in largeNum,
// and the smaller in smallNum.
module fpuAddSubSorter
  (input  fp16_t fpuIn1, fpuIn2,
   output fp16_t largeNum, smallNum);

  assign {largeNum, smallNum} = ({fpuIn1.exp, fpuIn1.frac} > {fpuIn2.exp, fpuIn2.frac}) ? 
                                {fpuIn1, fpuIn2} : {fpuIn2, fpuIn1};
endmodule : fpuAddSubSorter

// Aligns binary points of large and small number.
module fpuAddSubAligner
  (input  fp16_t largeNum, smallNum,
   output fp16_t alignedSmallNum);

  logic [`FP16_EXPW - 1:0] expDiff;
  logic [`FP16_FRACW:0] extFrac;

  always_comb begin
    expDiff = largeNum.exp - smallNum.exp;
    alignedSmallNum.sign = smallNum.sign;
    alignedSmallNum.exp = largeNum.exp; 
    extFrac = $signed({smallNum.exp != '0 ? 1'b1 : 1'b0, smallNum.frac}) >>> expDiff;
  end

  assign alignedSmallNum.frac = extFrac[`FP16_FRACW:1];
endmodule : fpuAddSubAligner
