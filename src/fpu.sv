/*
* fpu.sv: Top, system module of the FPU.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"

//TODO: Make parameterized.
module fpu
  #(parameter type FP_T = fp16_t)
  (input  FP_T          fpuIn1, fpuIn2, fpuIn3,
   input  fpuOp_t       op,
   input  logic         clock, reset, start,
   output FP_T          fpuOut,
   output logic         fpuDone,
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
  FP_T fpuFMADOut;
  FP_T fpuFMSOut;
  FP_T fpuFNMADOut;
  FP_T fpuFNMSOut;

  // Condition codes set by operations.
  condCode_t addCondCodes;
  condCode_t subCondCodes;
  condCode_t mulCondCodes;
  condCode_t divCondCodes;
  condCode_t fmadCondCodes;
  condCode_t fmsCondCodes;
  condCode_t fnmadCondCodes;
  condCode_t fnmsCondCodes;

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
  opStatusFlag_t fmadStatusFlags;
  opStatusFlag_t fmsStatusFlags;
  opStatusFlag_t fnmadStatusFlags;
  opStatusFlag_t fnmsStatusFlags;

  // Done signals
  logic mulDone, divDone, fmadDone, fmsDone, fnmadDone, fnmsDone;

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

  fpuFMAD #(.FP_T(FP_T), .FRACW(FRACW), .EXPW(EXPW), .EXP_MAX(EXP_MAX), .BIAS(BIAS))
         fpuFMAD(.fpuIn1, .fpuIn2, .fpuIn3, .clock, .reset, .start, .sub(1'b0),
                 .negate(1'b0), .fpuOut(fpuFMADOut), .done(fmadDone),
                 .condCodes(fmadCondCodes),
                 .opStatusFlags(fmadStatusFlags)),
         fpuFMS(.fpuIn1, .fpuIn2, .fpuIn3, .clock, .reset, .start, .sub(1'b1), 
                .negate(1'b0), .fpuOut(fpuFMSOut), .done(fmsDone), .condCodes(fmsCondCodes), 
                .opStatusFlags(fmsStatusFlags)),
         fpuFNMAD(.fpuIn1, .fpuIn2, .fpuIn3, .clock, .reset, .start, .sub(1'b0), .negate(1'b1),
                  .fpuOut(fpuFNMADOut), .done(fnmadDone), .condCodes(fnmadCondCodes), 
                  .opStatusFlags(fnmadStatusFlags)),
         fpuFNMS(.fpuIn1, .fpuIn2, .fpuIn3, .clock, .reset, .start, .sub(1'b1), .negate(1'b1),
                 .fpuOut(fpuFNMSOut), .done(fnmsDone), .condCodes(fnmsCondCodes), 
                 .opStatusFlags(fnmsStatusFlags));


  always_comb begin
    unique case (op)
      FPU_ADD: begin
        fpuOut = (anyNaNs) ? NAN : fpuAddOut;
        condCodes = addCondCodes;
        opStatusFlags = addStatusFlags;
        fpuDone = 1;
      end

      FPU_SUB: begin
        fpuOut = (anyNaNs) ? NAN : fpuSubOut;
        condCodes = subCondCodes;
        opStatusFlags = subStatusFlags;
        fpuDone = 1;
      end

      FPU_MUL: begin
        fpuOut = (anyNaNs) ? NAN : fpuMulOut;
        condCodes = mulCondCodes;
        opStatusFlags = mulStatusFlags;
        fpuDone = mulDone;
      end

      FPU_DIV: begin
        fpuOut = (anyNaNs) ? NAN : fpuDivOut;
        condCodes = divCondCodes;
        opStatusFlags = divStatusFlags;
        fpuDone = divDone;
      end

      FPU_FMAD: begin
        fpuOut = (anyNaNs) ? NAN : fpuFMADOut;
        condCodes = fmadCondCodes;
        opStatusFlags = fmadStatusFlags;
        fpuDone = fmadDone;
      end

      FPU_FMS: begin
        fpuOut = (anyNaNs) ? NAN : fpuFMSOut;
        condCodes = fmsCondCodes;
        opStatusFlags = fmsStatusFlags;
        fpuDone = fmsDone;
      end
      
      FPU_FNMAD: begin
        fpuOut = (anyNaNs) ? NAN : fpuFNMADOut;
        condCodes = fnmadCondCodes;
        opStatusFlags = fnmadStatusFlags;
        fpuDone = fnmadDone;
      end

      FPU_FNMS: begin
        fpuOut = (anyNaNs) ? NAN : fpuFNMSOut;
        condCodes = fnmsCondCodes;
        opStatusFlags = fnmsStatusFlags;
        fpuDone = fnmsDone;
      end
    endcase
  end
endmodule : fpu
