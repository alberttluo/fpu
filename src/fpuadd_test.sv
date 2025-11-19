/*
* fpuadd_test.sv: A basic test bench for adding and subtracting.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "../src/constants.sv"

module fpuadd_test();
  logic [`BIT_WIDTH - 1:0] fpuIn1;
  logic [`BIT_WIDTH - 1:0] fpuIn2;
  fpuOp_t                  op;
  logic [`BIT_WIDTH - 1:0] fpuOut;
  logic [3:0]              condCodes;

  FPU DUT(.*);

  initial begin
    $monitor("fpuIn1(%b), fpuIn2(%b), fpuOut(%b), condCodes(%b)\n",
             fpuIn1, fpuIn2, fpuOut, condCodes,
             "S1(%b)E1(%b)M1(%b), S2(%b)E2(%b)M2(%b)\n",
             DUT.fpuInS1, DUT.fpuInE1, DUT.fpuInM1,
             DUT.fpuInS2, DUT.fpuInE2, DUT.fpuInM2,
             "fpuAddSubOutSignedM(%b)",
             DUT.fpuAdder.fpuAddSubOutSignedM);


    fpuIn1 <= '0;
    fpuIn2 <= '0;
    op <= FPU_ADD;

    #10;

    fpuIn1 <= 32'd1;
    fpuIn2 <= 32'd2;
    op <= FPU_ADD;

    #10;

    $finish;
  end
endmodule : fpuadd_test
