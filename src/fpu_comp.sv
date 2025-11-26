/*
* fpu_comp.sv: Implements basic comparison operations.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

module fpuComp16
  (input  fp16_t fpuIn1, fpuIn2,
   output logic  lt, eq, gt);

  logic [14:0] mag1;
  logic [14:0] mag2;
  logic magLt;
  logic magGt;

  assign mag1 = {fpuIn1.exp, fpuIn1.frac};
  assign mag2 = {fpuIn2.exp, fpuIn2.frac};
  assign magLt = (mag1 < mag2);
  assign magEq = (mag1 == mag2);
  assign magGt = (mag1 > mag2);

  assign lt = (fpuIn1.sign & fpuIn2.sign & magGt) |
              (~fpuIn1.sign & ~fpuIn2.sign & magLt) |
              (fpuIn1.sign & ~fpuIn2.sign);

  assign eq = (fpuIn1 == fpuIn2);

  assign gt = (fpuIn1.sign & fpuIn2.sign & magLt) |
              (~fpuIn1.sign & ~fpuIn2.sign & magGt) |
              (~fpuIn1.sign & fpuIn2.sign);
endmodule : fpuComp16
