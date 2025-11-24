/*
* aligner.sv: Aligns binary points for addition/subtraction of two floating
* point inputs.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"

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
