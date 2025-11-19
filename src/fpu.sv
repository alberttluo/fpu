/*
* fpu.sv: Top, system module of the FPU. Supports 6 different operations,
* currently only for full-precision (FP32).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"

module FPU
  (input  logic [`BIT_WIDTH - 1:0] fpuIn1, fpuIn2,
   input  fpuOp_t                  op,
   output logic [`BIT_WIDTH - 1:0] fpuOut,
   output logic [3:0]              condCodes);

  // Condition codes to set.
  logic Z, C, N, V;

  // Floating point bit parts.
  logic fpuInS1, fpuInS2;
  logic [`EXP_WIDTH - 1:0] fpuInE1;
  logic [`EXP_WIDTH - 1:0] fpuInE2;
  logic [`MANTISSA_WIDTH - 1:0] fpuInM1;
  logic [`MANTISSA_WIDTH - 1:0] fpuInM2;

  // Break down each input into their sign, exponent, and mantissa parts.
  assign fpuInS1 = fpuIn1[`BIT_WIDTH - 1];
  assign fpuInS2 = fpuIn2[`BIT_WIDTH - 1];
  assign fpuInE1 = fpuIn1[`EXP_HI:`EXP_LO];
  assign fpuInE2 = fpuIn2[`EXP_HI:`EXP_LO];
  assign fpuInM1 = fpuIn1[`MANTISSA_HI:`MANTISSA_LO];
  assign fpuInM2 = fpuIn2[`MANTISSA_HI:`MANTISSA_LO];

  logic [`BIT_WIDTH - 1:0] fpuAddOut;
  logic [`BIT_WIDTH - 1:0] fpuSubOut;
  logic [3:0]              addCondCodes;
  logic [3:0]              subCondCodes;

  fpuAddSub fpuAdder(.sub(1'b0), .fpuAddSubIn1(fpuIn1), .fpuAddSubIn2(fpuIn2),
                     .fpuAddSubS1(fpuInS1), .fpuAddSubS2(fpuInS2),
                     .fpuAddSubE1(fpuInE1), .fpuAddSubE2(fpuInE2),
                     .fpuAddSubM1(fpuInM1), .fpuAddSubM2(fpuInM2),
                     .fpuAddSubOut(fpuAddOut), .condCodes(addCondCodes));

  fpuAddSub fpuSubtracter(.sub(1'b1), .fpuAddSubIn1(fpuIn1), .fpuAddSubIn2(fpuIn2),
                          .fpuAddSubS1(fpuInS1), .fpuAddSubS2(fpuInS2),
                          .fpuAddSubE1(fpuInE1), .fpuAddSubE2(fpuInE2),
                          .fpuAddSubM1(fpuInM1), .fpuAddSubM2(fpuInM2),
                          .fpuAddSubOut(fpuSubOut), .condCodes(subCondCodes));
  always_comb begin
    // Unset all condition codes by default.
    Z = 0;
    C = 0;
    N = 0;
    V = 0;

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
      end

      FPU_DIV: begin
      end

      FPU_SHL: begin
      end

      FPU_SHR: begin
      end
    endcase
  end
endmodule : FPU
