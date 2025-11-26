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
  (input  logic  sub,
   input  fp16_t largeNum, smallNum,
   output fp16_t alignedSmallNum);

  logic [`FP16_EXPW - 1:0] expDiff;
  logic [`FP16_FRACW:0] extFrac;
  logic [`FP16_FRACW:0] extFracNeg;

  always_comb begin
    expDiff = largeNum.exp - smallNum.exp;

    // Effective sign -- flip if subtraction so we can always add.
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
  (input  addSubUnnorm16_t addUnnormIn,
   input  mulUnnorm16_t    mulUnnormIn,
   output fp16_t           addNormOut, mulNormOut);

  // Leading zeros count (not including carry out).
  // Technically, this is leading zeros count + 1, but we store it for shifting
  // purposes.
  logic [$clog2(`FP16_FRACW + 1) - 1:0] lzcAdd;
  logic [$clog2(2 * `FP16_FRACW + 2) - 1:0] lzcMul;

  always_comb begin
    if (addUnnormIn.frac[`FP16_FRACW - 1]) lzcAdd = 1;
    else if (addUnnormIn.frac[`FP16_FRACW - 2]) lzcAdd = 2;
    else if (addUnnormIn.frac[`FP16_FRACW - 3]) lzcAdd = 3;
    else if (addUnnormIn.frac[`FP16_FRACW - 4]) lzcAdd = 4;
    else if (addUnnormIn.frac[`FP16_FRACW - 5]) lzcAdd = 5;
    else if (addUnnormIn.frac[`FP16_FRACW - 6]) lzcAdd = 6;
    else if (addUnnormIn.frac[`FP16_FRACW - 7]) lzcAdd = 7;
    else if (addUnnormIn.frac[`FP16_FRACW - 8]) lzcAdd = 8;
    else if (addUnnormIn.frac[`FP16_FRACW - 9]) lzcAdd = 9;
    else lzcAdd = 10;
  end

  always_comb begin
    if (mulUnnormIn.frac[2 * `FP16_FRACW - 1]) lzcMul = 1;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 2]) lzcMul = 2;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 3]) lzcMul = 3;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 4]) lzcMul = 4;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 5]) lzcMul = 5;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 6]) lzcMul = 6;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 7]) lzcMul = 7;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 8]) lzcMul = 8;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 9]) lzcMul = 9;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 10]) lzcMul = 10;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 11]) lzcMul = 11;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 12]) lzcMul = 12;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 13]) lzcMul = 13;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 14]) lzcMul = 14;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 15]) lzcMul = 15;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 16]) lzcMul = 16;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 17]) lzcMul = 17;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 18]) lzcMul = 18;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 19]) lzcMul = 19;
    else if (mulUnnormIn.frac[2 * `FP16_FRACW - 20]) lzcMul = 20;
    else lzcMul = 21;
  end

  always_comb begin
    addNormOut.sign = addUnnormIn.sign;
    if (addUnnormIn.leadingInt > 1) begin
      addNormOut.exp = addUnnormIn.exp + 1;
      addNormOut.frac = {addUnnormIn.leadingInt, addUnnormIn.frac} >> 1;
    end

    else if (addUnnormIn.leadingInt == 0) begin
      // TODO: Deal with overflow case.
      if (lzcAdd <= addUnnormIn.exp) begin
        addNormOut.exp = addUnnormIn.exp - lzcAdd;
        addNormOut.frac = addUnnormIn.frac << lzcAdd;
      end

      else begin
        addNormOut.sign = '0;
        addNormOut.exp = '0;
        addNormOut.frac = '0;
      end
    end

    else begin
      addNormOut.exp = addUnnormIn.exp;
      addNormOut.frac = addUnnormIn.frac;
    end
  end

  always_comb begin
    mulNormOut.sign = mulUnnormIn.sign;
    if (mulUnnormIn.leadingInt > 1) begin
      mulNormOut.exp = mulUnnormIn.exp + 1;
      mulNormOut.frac = {mulUnnormIn.leadingInt, mulUnnormIn.frac} >> 1;
    end

    else if (mulUnnormIn.leadingInt == 0) begin
      // TODO: Deal with overflow case.
      if (lzcMul <= mulUnnormIn.exp) begin
        mulNormOut.exp = mulUnnormIn.exp - lzcMul;
        mulNormOut.frac = mulUnnormIn.frac << lzcMul;
      end

      else begin
        mulNormOut.sign = '0;
        mulNormOut.exp = '0;
        mulNormOut.frac = '0;
      end
    end

    else begin
      mulNormOut.exp = mulUnnormIn.exp;
      mulNormOut.frac = mulUnnormIn.frac;
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
