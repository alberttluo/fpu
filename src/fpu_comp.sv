/*
* fpu_comp.sv: Implements basic comparison operations.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

module fpuComp
  #(parameter type FP_T = fp16_t)
  (input  FP_T   fpuIn1, fpuIn2,
   input  logic  isInf1, isInf2,
   input  logic  isNaN1, isNaN2,
   output logic  lt, eq, gt);

  localparam int MAG_WIDTH = $bits(fpuIn1) - 1;

  logic [MAG_WIDTH - 1:0] mag1;
  logic [MAG_WIDTH - 1:0] mag2;
  logic magLt;
  logic magGt;

  logic noNaNs, noInfs;
  assign noNaNs = (~isNaN1 & ~isNaN2);
  assign noInfs = (~isInf1 & ~isInf2);

  assign mag1 = {fpuIn1.exp, fpuIn1.frac};
  assign mag2 = {fpuIn2.exp, fpuIn2.frac};
  assign magLt = (mag1 < mag2);
  assign magGt = (mag1 > mag2);

  assign lt = ((fpuIn1.sign & fpuIn2.sign & magGt) |
               (~fpuIn1.sign & ~fpuIn2.sign & magLt) |
               (fpuIn1.sign & ~fpuIn2.sign) |
               // Less than always true if fpuIn1 = -inf, unless fpuIn2 = -inf
               // as well, in which case less than is false.
               (isInf1 & fpuIn1.sign)) & noNaNs & ~(isInf2 & fpuIn2.sign);

  assign eq = ((fpuIn1 == fpuIn2) | (isInf1 & isInf2 & fpuIn1.sign == fpuIn2.sign)) & noNaNs;

  assign gt = ((fpuIn1.sign & fpuIn2.sign & magLt) |
               (~fpuIn1.sign & ~fpuIn2.sign & magGt) |
               (~fpuIn1.sign & fpuIn2.sign) |
               // Greater than always true if fpuIn1 = inf, unless fpuIn2 = inf
               // as well, in which case greater than is false.
               (isInf1 & ~fpuIn1.sign)) & noNaNs & ~(isInf2 & ~fpuIn2.sign);
endmodule : fpuComp
