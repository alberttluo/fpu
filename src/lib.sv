/*
* lib.sv: A library file for all floating point operations.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef sv_LIB
`define sv_LIB

`include "constants.sv"

/*
* Aligns binary points for addition/subtraction of two floating
* point inputs.
*/
module fpuAddSubAligner
  (input  fp16_t largeNum, smallNum,
   output fp16_t alignedSmallNum);

  logic [`FP16_EXPW - 1:0] expDiff;
  logic [`FP16_FRACW:0] extFrac;

  always_comb begin
    expDiff = largeNum.exp - smallNum.exp;
    alignedSmallNum.sign = smallNum.sign;
    alignedSmallNum.exp = largeNum.exp;
    // Denormalized values have leading 0 instead of leading 1.
    extFrac = {smallNum.exp != '0 ? 1'b1 : 1'b0, smallNum.frac} >> expDiff;
  end

  assign alignedSmallNum.frac = extFrac[`FP16_FRACW - 1:0];
endmodule : fpuAddSubAligner


/*
* Normalizes floating point values based on precision type and
* operation. Currently only supports half-precision.
*/
module fpuNormalizer16
  (input  logic C,
   input  fp16_t unnormalizedIn,
   output fp16_t normalizedOut);

  // Leading zeros count (not including carry out).
  logic [$clog2(`FP16_FRACW + 1) - 1:0] lzc;

  always_comb begin
    if (unnormalizedIn.frac[`FP16_FRACW:0]) lzc = 1;
    else if (unnormalizedIn.frac[`FP16_FRACW - 1:0]) lzc = 2;
    else if (unnormalizedIn.frac[`FP16_FRACW - 2:0]) lzc = 3;
    else if (unnormalizedIn.frac[`FP16_FRACW - 3:0]) lzc = 4;
    else if (unnormalizedIn.frac[`FP16_FRACW - 4:0]) lzc = 5;
    else if (unnormalizedIn.frac[`FP16_FRACW - 5:0]) lzc = 6;
    else if (unnormalizedIn.frac[`FP16_FRACW - 6:0]) lzc = 7;
    else if (unnormalizedIn.frac[`FP16_FRACW - 7:0]) lzc = 8;
    else if (unnormalizedIn.frac[`FP16_FRACW - 8:0]) lzc = 9;
    else lzc = 10;
  end

  always_comb begin
    normalizedOut.sign = unnormalizedIn.sign;
    if (C) begin
      normalizedOut.frac = unnormalizedIn.frac >> 1;
      normalizedOut.exp = unnormalizedIn.exp + 1;
    end
    else if (lzc <= unnormalizedIn.exp) begin
      normalizedOut.frac = unnormalizedIn.frac << lzc;
      normalizedOut.exp = unnormalizedIn.exp - lzc;
    end
    else begin
      normalizedOut.exp = '0;
      normalizedOut.frac = '0;
    end
  end
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
