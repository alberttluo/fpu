/*
* fpuaddsub_test.sv: A basic test bench for adding and subtracting.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "lib.sv"

module fpuaddsub_test();
  logic         sub;
  fp16_t        fpuIn1;
  fp16_t        fpuIn2;
  fpuOp_t       op; // Useless if just testing ALU operations.
  fp16_t        fpuOut;
  condCode_t    condCodes;
  addSubDebug_t addSubView;

  fpuAddSub16 DUT(.*);

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
             "expDiff(%d)\n",
             addSubView.expDiff,
             "=====================================================\n");
    #10;
  endtask

  initial begin
    $display("Testing 1 + 0...");
    sub <= '0;
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

    $display("Testing 4 + 2...");
    fpuIn1 <= 16'h4400;
    fpuIn2 <= 16'h4000;
    op <= FPU_ADD;
    #10;
    displayInfo();

    $display("Testing 4 + 17...");
    fpuIn1 <= 16'h4400;
    fpuIn2 <= 16'h4C40;
    op <= FPU_ADD;
    #10;
    displayInfo();

    $display("Testing 444 + 783...");
    fpuIn1 <= 16'h5EF0;
    fpuIn2 <= 16'h621E;
    op <= FPU_ADD;
    #10;
    displayInfo();

    $display("Testing 1 - 1...");
    fpuIn1 <= 16'h3C00;
    fpuIn2 <= 16'h3C00;
    sub <= '1;
    op <= FPU_SUB;
    #10;
    displayInfo();

    $display("Testing 1 - 2...");
    fpuIn1 <= 16'h3C00;
    fpuIn2 <= 16'h4000;
    sub <= '1;
    op <= FPU_SUB;
    #10;
    displayInfo();

    $display("Testing 10 - 3...");
    fpuIn1 <= 16'h4900;
    fpuIn2 <= 16'h4200;
    sub <= '1;
    op <= FPU_SUB;
    #10;
    displayInfo();

    $display("Testing 398 - 52...");
    fpuIn1 <= 16'h5E38;
    fpuIn2 <= 16'h5280;
    sub <= '1;
    op <= FPU_SUB;
    #10;
    displayInfo();

    $display("Testing -1 + 1...");
    fpuIn1 <= 16'hBC00;
    fpuIn2 <= 16'h3C00;
    sub <= '0;
    op <= FPU_ADD;
    #10;
    displayInfo();

    $display("Testing -1 + 5...");
    fpuIn1 <= 16'hBC00;
    fpuIn2 <= 16'h4500;
    sub <= '0;
    op <= FPU_ADD;
    #10;
    displayInfo();

    // Tests that cause rounding issues.
    $display("Testing -444 + 8972...");
    fpuIn1 <= 16'hDEF0;
    fpuIn2 <= 16'h7062;
    sub <= '0;
    op <= FPU_ADD;
    #10;
    displayInfo();

    $display("Testing -3210 + 5019...");
    fpuIn1 <= 16'hEA45;
    fpuIn2 <= 16'h6CE7;
    sub <= '0;
    op <= FPU_ADD;
    #10;
    displayInfo();
    $finish;
  end
endmodule : fpuaddsub_test
