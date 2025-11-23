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
  logic [3:0]              condCodes;

  FPU DUT(.*);

  initial begin
    $monitor("fpuIn1(%b)    fpuIn2(%b)\n",
             fpuIn1, fpuIn2,
             "fpuOP(%s)\n",
             op.name,
             "fpuOut(%b)\n",
             fpuOut,
             "ZCNV(%b)\n",
             condCodes,
             "=====================================================\n");


    fpuIn1 <= 16'h3C00;
    fpuIn2 <= '0;
    op <= FPU_ADD;

    #10;

    fpuIn1 <= 16'h3C00;
    fpuIn2 <= 16'h3C00;
    op <= FPU_SUB;

    #10;

    fpuIn1 <= 16'h3C00;
    fpuIn2 <= 16'h0000;
    op <= FPU_SUB;

    #10;
    $finish;
  end
endmodule : fpuadd_test
