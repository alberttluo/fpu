/*
* fpuadd_test.sv: A basic test bench for adding and subtracting.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "../src/constants.sv"

module fpuadd_test();
  fp16_t        fpuIn1;
  fp16_t        fpuIn2;
  fpuOp_t       op;
  fp16_t        fpuOut;
  condCode_t    condCodes;
  addSubDebug_t addSubView;

  FPU16 DUT(.*);

  task displayInfo();
    $display("fpuIn1(%b)    fpuIn2(%b)\n",
             fpuIn1, fpuIn2,
             "S1(%b)E1(%b)frac(%b)    S2(%b)E2(%b)frac(%b)\n",
             fpuIn1.sign, fpuIn1.exp, fpuIn1.frac,
             fpuIn2.sign, fpuIn2.exp, fpuIn2.frac,
             "fpuOP(%s)\n",
             op.name,
             "fpuOut(%b)\n",
             fpuOut,
             "ZCNV(%b)\n",
             condCodes,
             "largeNum(%b) smallNum(%b) alignedSmallNum(%b)\n",
             addSubView.largeNum, addSubView.smallNum, addSubView.alignedSmallNum,
             "=====================================================\n");
    #10;
  endtask

  initial begin
    $display("Testing 1 + 0...");
    fpuIn1 <= 16'h3C00;
    fpuIn2 <= '0;
    op <= FPU_ADD;
    #10;
    displayInfo();

    $display("Testing 2 + 1...");
    fpuIn1 <= 16'h4000;
    fpuIn2 <= 16'h3C00;
    op <= FPU_ADD;
    #10;
    displayInfo();

    $display("Testing 1 - 1...");
    fpuIn1 <= 16'h3C00;
    fpuIn2 <= 16'h3C00;
    op <= FPU_SUB;
    #10;
    displayInfo();

    $display("Testing 1 - 0...");
    fpuIn1 <= 16'h3C00;
    fpuIn2 <= 16'h0000;
    op <= FPU_SUB;
    #10;
    displayInfo();

    $finish;
  end
endmodule : fpuadd_test
