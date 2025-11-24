/*
* fpu.sv: Top, system module of the FPU. Supports 6 different operations,
* currently only for full-precision (FP32).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"

module FPU16
  (input  fp16_t        fpuIn1, fpuIn2,
   input  fpuOp_t       op,
   output fp16_t        fpuOut,
   output condCode_t    condCodes,
   output addSubDebug_t addSubView);

  fp16_t fpuAddOut;
  fp16_t fpuSubOut;
  condCode_t addCondCodes;
  condCode_t subCondCodes;

  addSubDebug_t addView;
  addSubDebug_t subView;

  fpuAddSub16 fpuAdder(.sub(1'b0), .fpuIn1, .fpuIn2, .fpuOut(fpuAddOut),
                       .condCodes(addCondCodes), .addSubView(addView));
  fpuAddSub16 fpuSubtracter(.sub(1'b1), .fpuIn1, .fpuIn2, .fpuOut(fpuSubOut),
                            .condCodes(subCondCodes), .addSubView(subView));
            
  always_comb begin
    unique case (op)
      FPU_ADD: begin
        fpuOut = fpuAddOut;
        condCodes = addCondCodes;
        addSubView = addView;
      end

      FPU_SUB: begin
        fpuOut = fpuSubOut;
        condCodes = subCondCodes;
        addSubView = subView;
      end

      FPU_MUL: begin
      end

      FPU_DIV: begin
      end

      FPU_SHL: begin
      end

      FPU_SHR: begin
      end
    endcase
  end
endmodule : FPU16
