/*
* fpustatusflag_test.sv: Test that status flags are tested correctly. Currently
* only testing the flags set by the top FPU module (NV, DZ).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "fpu_lib.sv"

`define FINITE randomFinite()
`define NAN    randomNaN()

localparam fp16_t POS_INF = 16'h7C00,
                  NEG_INF = 16'hFC00,
                  ZERO    = 16'd0;

module fpuStatusFlag_test();
  fp16_t       fpuIn1, fpuIn2;
  fpuOp_t      op;
  logic        clock, reset, start;
  fp16_t       fpuOut;
  condCode_t   condCodes;
  statusFlag_t statusFlags;
  fpuComp_t    comps;

  fpu16 DUT(.*);

  fpuOp_t opArray[4] = '{FPU_ADD, FPU_SUB, FPU_MUL, FPU_DIV};

  int i;

  task automatic doOp
    (input fp16_t  in1,
     input fp16_t  in2,
     input fpuOp_t inOp);

    fpuIn1 <= in1;
    fpuIn2 <= in2;
    op <= inOp;
    #10;
  endtask

  function automatic fp16_t randomFinite();
    fp16_t val;

    do begin
      val = $urandom;
    end while (val == ZERO || val.exp == 5'b11111);

    return val;
  endfunction

  function automatic fp16_t randomNaN();
    logic sign;
    logic [`FP16_FRACW - 1:0] frac;

    do begin
      sign = $urandom;
      frac = $urandom;
    end while (frac == `FP16_FRACW'd0);

    return {sign, `FP16_EXPW'b11111, frac};
  endfunction

  // TODO: Wait for multiplication to finish + with clock.
  initial begin
    // Test NV is set properly for any NaN.
    foreach (opArray[i]) begin
      doOp(`NAN, `FINITE, opArray[i]);
      doOp(`FINITE, `NAN, opArray[i]);
    end

    // Test with infinities.
    foreach (opArray[i]) begin
      doOp(POS_INF, POS_INF, opArray[i]);
      doOp(NEG_INF, POS_INF, opArray[i]);
      doOp(POS_INF, NEG_INF, opArray[i]);
      doOp(NEG_INF, POS_INF, opArray[i]);
    end

    // Test mix of infinities and NaNs.
    foreach (opArray[i]) begin
      doOp(`NAN, POS_INF, opArray[i]);
      doOp(`NAN, NEG_INF, opArray[i]);
      doOp(POS_INF, `NAN, opArray[i]);
      doOp(NEG_INF, `NAN, opArray[i]);
    end

    // Test mix of finites and infinities.
    foreach (opArray[i]) begin
      doOp(`FINITE, POS_INF, opArray[i]);
      doOp(`FINITE, NEG_INF, opArray[i]);
      doOp(POS_INF, `FINITE, opArray[i]);
      doOp(NEG_INF, `FINITE, opArray[i]);
    end

    // Test division by 0.
    doOp(`FINITE, ZERO, FPU_DIV);
    doOp(POS_INF, ZERO, FPU_DIV);
    doOp(NEG_INF, ZERO, FPU_DIV);

    // Test inf x 0.
    doOp(ZERO, POS_INF, FPU_MUL);
    doOp(ZERO, NEG_INF, FPU_MUL);
    doOp(POS_INF, ZERO, FPU_MUL);
    doOp(NEG_INF, ZERO, FPU_MUL);

    $finish;
  end
endmodule : fpuStatusFlag_test
