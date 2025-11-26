/*
* fpu.sv: Top, system module of the FPU. Supports 4 different operations,
* currently only for half-precision (FP16).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"

//TODO: Make parameterized.

module FPU16
  (input  fp16_t        fpuIn1, fpuIn2,
   input  fpuOp_t       op,
   input  logic         clock, reset,
   output fp16_t        fpuOut,
   output condCode_t    condCodes,
   output fpuComp_t     comps);

  // Operation outputs.
  fp16_t fpuAddOut;
  fp16_t fpuSubOut;
  fp16_t fpuMulOut;
  fp16_t fpuDivOut;

  // Condition codes set by operations.
  condCode_t addCondCodes;
  condCode_t subCondCodes;
  condCode_t mulCondCodes;
  condCode_t divCondCodes;

  // Comparison/inequality signals.
  logic lt, eq, gt;
  assign comps = {lt, eq, gt};

  fpuComp16 fpuComp(.*);

  fpuAddSub16 fpuAdder(.sub(1'b0), .fpuIn1, .fpuIn2, .fpuOut(fpuAddOut),
                       .condCodes(addCondCodes));
  fpuAddSub16 fpuSubtracter(.sub(1'b1), .fpuIn1, .fpuIn2, .fpuOut(fpuSubOut),
                            .condCodes(subCondCodes));

  // TODO: Multiplier and divider.

  always_comb begin
    unique case (op)
      FPU_ADD: begin
        fpuOut = fpuAddOut;
        condCodes = addCondCodes;
      end

      FPU_SUB: begin
        fpuOut = fpuSubOut;
        condCodes = subCondCodes;
      end

      FPU_MUL: begin
        fpuOut = fpuMulOut;
        condCodes = mulCondCodes;
      end

      FPU_DIV: begin
        fpuOut = fpuDivOut;
        condCodes = divCondCodes;
      end
    endcase
  end
endmodule : FPU16
