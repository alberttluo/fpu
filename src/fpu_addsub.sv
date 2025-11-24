/*
* fpu_addsub.sv: Performs FPU addition/subtraction, given both inputs broken
* down into their sign, exponent, and mantissa parts. (done by FPU top module).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/
`default_nettype none

`include "constants.sv"
`include "lib.sv"

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
  logic [`FP16_FRACW - 1:0] fracSum;
  logic [`FP16_FRACW:0] extLargeFrac;
  logic [`FP16_FRACW:0] extSmallFrac;

  // Fields to build the unnormalized input.
  logic [1:0] intPart;

  assign extLargeFrac = (largeNum.exp == '0) ? {1'b0, largeNum.frac} :
                                               {1'b1, largeNum.frac};
  assign extSmallFrac = {1'b0, alignedSmallNum.frac};

  assign {intPart, fracSum} = (largeNum.sign == smallNum.sign) ?
                     (extLargeFrac + extSmallFrac) :
                     (extLargeFrac - extSmallFrac);

  // Normalize floating point fields.
  unnorm16_t unnormalizedIn;
  fp16_t normalizedOut;

  // Pack the fractional part along with largeNum fields to get unnormalized
  // value.
  assign unnormalizedIn = {largeNum.sign, intPart, largeNum.exp, fracSum};
  fpuNormalizer16 normalizer(.*);

  // Set condition codes.
  assign Z = (normalizedOut == '0);
  assign C = intPart[1];
  assign N = normalizedOut[15];
  assign V = (~sub & ~fpuIn1.sign & ~fpuIn2.sign & N) | (sub & fpuIn1.sign & fpuIn2.sign & ~N);

  assign fpuOut = normalizedOut;

  // assign addSubView = {
  //  largeNum,
  //  smallNum,
  //  aligner.expDiff,
  //  alignedSmallNum,
  //  extSigSum,
  //  unnormalizedIn,
  //  normalizedOut,
  //  fpuOut
  // };
endmodule : fpuAddSub16
