/*
* fpuadd_test.sv: A basic test bench for adding and subtracting.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "../src/constants.sv"

module fpuadd_test();
  localparam int test_BW = 16;
  localparam int test_EW = 5;
  localparam int test_SW = 10;

  logic [test_BW - 1:0] fpuIn1;
  logic [test_BW - 1:0] fpuIn2;
  fpuOp_t                  op;
  logic [test_BW - 1:0] fpuOut;
  logic [3:0]           condCodes;
  addSubDebug_t         addSubView;

  FPU DUT(.*);

  task displayAddInfo();
    $display("fpuIn1(%b)    fpuIn2(%b)\n",
             fpuIn1, fpuIn2,
             "S1(%b)E1(%b)Sig1(%b)    S2(%b)E2(%b)Sig2(%b)\n",
             DUT.fpuAdder.fpuAddSubS1, DUT.fpuAdder.fpuAddSubE1, DUT.fpuAdder.fpuAddSubSig1,
             DUT.fpuAdder.fpuAddSubS2, DUT.fpuAdder.fpuAddSubE2, DUT.fpuAdder.fpuAddSubSig2,
             "fpuOP(%s)\n",
             op.name,
             "fpuOut(%b)\n",
             fpuOut,
             "ZCNV(%b)\n",
             condCodes,
             "shiftIn1(%b), effS2(%b), adjExp(%b), adjSig(%b), nonAdjSig(%b), extSigOut(%b)\n",
             DUT.fpuAdder.shiftIn1, DUT.fpuAdder.effS2, DUT.fpuAdder.adjExp, DUT.fpuAdder.adjSig, 
             DUT.fpuAdder.nonAdjSig, DUT.fpuAdder.extSigOut,
             "=====================================================\n");
    #10;
  endtask

  task displaySubInfo();
    $display("fpuIn1(%b)    fpuIn2(%b)\n",
             fpuIn1, fpuIn2,
             "S1(%b)E1(%b)Sig1(%b)    S2(%b)E2(%b)Sig2(%b)\n",
             DUT.fpuSubtracter.fpuAddSubS1, DUT.fpuSubtracter.fpuAddSubE1, DUT.fpuSubtracter.fpuAddSubSig1,
             DUT.fpuSubtracter.fpuAddSubS2, DUT.fpuSubtracter.fpuAddSubE2, DUT.fpuSubtracter.fpuAddSubSig2,
             "fpuOP(%s)\n",
             op.name,
             "fpuOut(%b)\n",
             fpuOut,
             "ZCNV(%b)\n",
             condCodes,
             "shiftIn1(%b), effS2(%b), adjExp(%b), adjSig(%b), nonAdjSig(%b), extSigOut(%b)\n",
             DUT.fpuSubtracter.shiftIn1, DUT.fpuSubtracter.effS2, DUT.fpuSubtracter.adjExp, DUT.fpuSubtracter.adjSig, 
             DUT.fpuSubtracter.nonAdjSig, DUT.fpuSubtracter.extSigOut,
             "=====================================================\n");
    #10;
  endtask

  initial begin
    $display("Testing 1 + 0...");
    fpuIn1 <= 16'h3C00;
    fpuIn2 <= '0;
    op <= FPU_ADD;

    #10;

    displayAddInfo();

    $display("Testing 2 + 1...");
    fpuIn1 <= 16'h4000;
    fpuIn2 <= 16'h3C00;
    op <= FPU_ADD;

    #10;

    displayAddInfo();

    $display("Testing 1 - 0...");
    fpuIn1 <= 16'h3C00;
    fpuIn2 <= 16'h0000;
    op <= FPU_SUB;

    #10;

    displaySubInfo();
    $finish;
  end
endmodule : fpuadd_test
