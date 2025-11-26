/*
* aligner_test.sv: Basic test bench to test that the aligner is working.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "fpu_lib.sv"

module aligner_test();
  fp16_t largeNum;
  fp16_t smallNum;
  fp16_t alignedSmallNum;
  logic sticky;

  fpuAddSubAligner DUT(.*);

  initial begin
    // Test 0s (everything should remain the same).
    largeNum <= '0;
    smallNum <= '0;

    #10;

    // Should align to 0_00010_0001111111;
    largeNum <= 16'b1_00010_0111111111;
    smallNum <= 16'b0_00000_0111111111;

    #10;

    // Should align to 1_10111_0000001100;
    largeNum <= 16'b1_10111_0000000000;
    smallNum <= 16'b1_10000_1000000000;

    #10;

    $finish;
  end
endmodule : aligner_test

