/*
* fpu.sv: Top, system module of the FPU. Supports 4 different operations,
* currently only for half-precision (FP16).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"

//TODO: Make parameterized.
module fpu16
  (input  fp16_t        fpuIn1, fpuIn2,
   input  fpuOp_t       op,
   input  logic         clock, reset, start,
   output fp16_t        fpuOut,
   output logic         mulDone,
   output condCode_t    condCodes,
   output statusFlag_t  statusFlags,
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

  // Special value logic.
  logic isInf1, isInf2, isNaN1, isNaN2;
  fpuIsSpecialValue specVal1(.fpuIn(fpuIn1), .inf(isInf1), .nan(isNaN1)),
                    specval2(.fpuIn(fpuIn2), .inf(isInf2), .nan(isNaN2));

  // Status flags set by the operation.
  opStatusFlag_t opStatusFlags;

  // Explicit status flags (only NV, DZ are set by top fpu module).
  logic NV, DZ;
  assign statusFlags = {NV, DZ, opStatusFlags};

  assign NV = (isNaN1 || isNaN2) ||
              // Opposite signed infinites add/sub.
              (isInf1 && isInf2 && (fpuIn1.sign ^ fpuIn2.sign) && (op == FPU_ADD || op == FPU_SUB)) ||
              // 0 x inf
              ((op == FPU_MUL) && (isInf1 && fpuIn2 == 16'd0) || (isInf2 && fpuIn1 == 16'd0)) ||
              // inf/inf
              ((op == FPU_DIV) && (isInf1 && isInf2));

  assign DZ = (op == FPU_DIV && {fpuIn2.exp, fpuIn2.frac} == 15'd0);

  opStatusFlag_t addStatusFlags;
  opStatusFlag_t subStatusFlags;
  opStatusFlag_t mulStatusFlags;
  opStatusFlag_t divStatusFlags;

  // Comparison/inequality signals.
  logic lt, eq, gt;
  assign comps = {lt, eq, gt};

  fpuComp16 fpuComp(.*);

  fpuAddSub16 fpuAdder(.sub(1'b0), .fpuIn1, .fpuIn2, .fpuOut(fpuAddOut),
                       .condCodes(addCondCodes), .opStatusFlags(addStatusFlags));
  fpuAddSub16 fpuSubtracter(.sub(1'b1), .fpuIn1, .fpuIn2, .fpuOut(fpuSubOut),
                            .condCodes(subCondCodes), .opStatusFlags(subStatusFlags));

  // TODO: Create FSM to wait for multiplication to finish.
  fpuMul16 fpuMultiplier(.fpuIn1, .fpuIn2, .clock, .reset, .start, .fpuOut(fpuMulOut),
                         .condCodes(mulCondCodes), .opStatusFlags(mulStatusFlags),
                         .done(mulDone));

  // TODO: Multiplier and divider.

  always_comb begin
    unique case (op)
      FPU_ADD: begin
        fpuOut = fpuAddOut;
        condCodes = addCondCodes;
        opStatusFlags = addStatusFlags;
      end

      FPU_SUB: begin
        fpuOut = fpuSubOut;
        condCodes = subCondCodes;
        opStatusFlags = subStatusFlags;
      end

      FPU_MUL: begin
        fpuOut = fpuMulOut;
        condCodes = mulCondCodes;
        opStatusFlags = mulStatusFlags;
      end

      FPU_DIV: begin
        fpuOut = fpuDivOut;
        condCodes = divCondCodes;
        opStatusFlags = divStatusFlags;
      end
    endcase
  end
endmodule : fpu16
