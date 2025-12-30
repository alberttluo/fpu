/*
* fpu.sv: Top, system module of the FPU.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"

//TODO: Make parameterized.
module fpu
  #(parameter type FP_T = fp16_t)
  (input  FP_T          fpuIn1, fpuIn2,
   input  fpuOp_t       op,
   input  logic         clock, reset, start,
   output FP_T          fpuOut,
   output logic         mulDone,
   output logic         divDone,
   output condCode_t    condCodes,
   output statusFlag_t  statusFlags,
   output fpuComp_t     comps);

  localparam int WIDTH = $bits(FP_T);
  localparam int FRACW = $bits(fpuIn1.frac);
  localparam int EXPW = $bits(fpuIn1.exp);
  localparam int EXP_MAX = (1 << EXPW) - 2;
  localparam int BIAS = (1 << (EXPW - 1)) - 1;

  localparam logic [WIDTH - 1:0] NAN = (WIDTH == 16) ? `FP16_NAN :
                                       ((WIDTH == 32) ? `FP32_NAN : `FP64_NAN);

  // Operation outputs.
  FP_T fpuAddOut;
  FP_T fpuSubOut;
  FP_T fpuMulOut;
  FP_T fpuDivOut;

  // Condition codes set by operations.
  condCode_t addCondCodes;
  condCode_t subCondCodes;
  condCode_t mulCondCodes;
  condCode_t divCondCodes;

  // Special value logic.
  logic isInf1, isInf2, isNaN1, isNaN2;
  fpuIsSpecialValue #(.FP_T(FP_T), .FRACW(FRACW), .EXPW(EXPW))
                    specVal1(.fpuIn(fpuIn1), .inf(isInf1), .nan(isNaN1)),
                    specval2(.fpuIn(fpuIn2), .inf(isInf2), .nan(isNaN2));

  logic anyNaNs;
  assign anyNaNs = (isNaN1 | isNaN2);

  // Status flags set by the operation.
  opStatusFlag_t opStatusFlags;

  // Explicit status flags (only NV, DZ are set by top fpu module).
  logic NV, DZ;
  assign statusFlags = {NV, DZ, opStatusFlags};

  assign NV = anyNaNs ||
              // Opposite signed infinites add/sub.
              (isInf1 && isInf2 && (fpuIn1.sign ^ fpuIn2.sign) && (op == FPU_ADD || op == FPU_SUB)) ||
              // 0 x inf
              ((op == FPU_MUL) && (isInf1 && fpuIn2 == 0) || (isInf2 && fpuIn1 == 0)) ||
              // inf/inf
              ((op == FPU_DIV) && (isInf1 && isInf2));

  assign DZ = (op == FPU_DIV && {fpuIn2.exp, fpuIn2.frac} == 0);

  opStatusFlag_t addStatusFlags;
  opStatusFlag_t subStatusFlags;
  opStatusFlag_t mulStatusFlags;
  opStatusFlag_t divStatusFlags;

  // Comparison/inequality signals.
  logic lt, eq, gt;
  assign comps = {lt, eq, gt};

  fpuComp #(.FP_T(FP_T)) fpuComp(.*);

  fpuAddSub #(.FP_T(FP_T), .FRACW(FRACW), .EXPW(EXPW), .EXP_MAX(EXP_MAX), .BIAS(BIAS)) 
            fpuAdder(.sub(1'b0), .fpuIn1, .fpuIn2, .fpuOut(fpuAddOut),
                     .condCodes(addCondCodes), .opStatusFlags(addStatusFlags)),
            fpuSubtracter(.sub(1'b1), .fpuIn1, .fpuIn2, .fpuOut(fpuSubOut),
                          .condCodes(subCondCodes), .opStatusFlags(subStatusFlags));

  // TODO: Create FSM to wait for multiplication to finish.
  fpuMul #(.FP_T(FP_T), .FRACW(FRACW), .EXPW(EXPW), .EXP_MAX(EXP_MAX), .BIAS(BIAS))
         fpuMultiplier(.fpuIn1, .fpuIn2, .clock, .reset, .start, .fpuOut(fpuMulOut),
                       .condCodes(mulCondCodes), .opStatusFlags(mulStatusFlags),
                       .done(mulDone));

  fpuDiv #(.FP_T(FP_T), .FRACW(FRACW), .EXPW(EXPW), .EXP_MAX(EXP_MAX), .BIAS(BIAS))
         fpuDivider(.fpuIn1, .fpuIn2, .clock, .reset, .start,
                    .fpuOut(fpuDivOut), .done(divDone), .condCodes(divCondCodes),
                    .opStatusFlags(divStatusFlags));

  always_comb begin
    unique case (op)
      FPU_ADD: begin
        fpuOut = (anyNaNs) ? NAN : fpuAddOut;
        condCodes = addCondCodes;
        opStatusFlags = addStatusFlags;
      end

      FPU_SUB: begin
        fpuOut = (anyNaNs) ? NAN : fpuSubOut;
        condCodes = subCondCodes;
        opStatusFlags = subStatusFlags;
      end

      FPU_MUL: begin
        fpuOut = (anyNaNs) ? NAN : fpuMulOut;
        condCodes = mulCondCodes;
        opStatusFlags = mulStatusFlags;
      end

      FPU_DIV: begin
        fpuOut = (anyNaNs) ? NAN : fpuDivOut;
        condCodes = divCondCodes;
        opStatusFlags = divStatusFlags;
      end
    endcase
  end
endmodule : fpu
