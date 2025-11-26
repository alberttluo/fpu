/*
* fpucomp_test.sv: Testbench for comparisons.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"

module fpuComp_test();
  fp16_t fpuIn1;
  fp16_t fpuIn2;
  logic lt, eq, gt;

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
    $finish;
  end
endmodule : fpuComp_test
