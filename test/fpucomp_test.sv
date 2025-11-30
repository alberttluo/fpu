/*
* fpucomp_test.sv: Testbench for comparisons.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
localparam int POS_INF = 16'h7C00;
localparam int NEG_INF = 16'hFC00;

module fpuComp_test();
  fp16_t fpuIn1;
  fp16_t fpuIn2;
  logic isInf1, isInf2, isNaN1, isNaN2;
  logic lt, eq, gt;

  fpuIsSpecialValue specVal1(.fpuIn(fpuIn1), .inf(isInf1), .nan(isNaN1)),
                    specval2(.fpuIn(fpuIn2), .inf(isInf2), .nan(isNaN2));

  fpuComp16 DUT(.*);

  task automatic doComp
    (input fp16_t in1,
     input fp16_t in2);

    fpuIn1 <= in1;
    fpuIn2 <= in2;

    #10;
    $display("Result of comparisons between %h and %h: lt(%b) eq(%b) gt(%b)\n",
             in1, in2, lt, eq, gt);
    #10;
  endtask

  initial begin
    // Test 1, 1
    doComp(16'h3C00, 16'h3C00);

    // Test -14, 119
    doComp(16'hCB00, 16'h5770);

    // Test 14.564, 7.933
    doComp(16'h4B48, 16'h47D5);

    // Test -inf, -inf
    doComp(NEG_INF, NEG_INF);

    // Test inf, inf
    doComp(POS_INF, POS_INF);

    // Test -inf, inf
    doComp(NEG_INF, POS_INF);

    // Test inf, -inf
    doComp(POS_INF, NEG_INF);

    // Test finite, inf
    doComp(16'hCB00, POS_INF);

    // Test finite, -inf
    doComp(16'hCB00, NEG_INF);

    // Test inf, finite
    doComp(POS_INF, 16'hCB00);

    // Test -inf, finite
    doComp(NEG_INF, 16'hCB00);
    $finish;
  end
endmodule : fpuComp_test
