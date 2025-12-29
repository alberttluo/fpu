/*
* fpudiv_test.sv: Testbench for floating point division.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"

module fpudiv_test();
  localparam type FP_T = fp16_t;

  FP_T fpuIn1;
  FP_T fpuIn2;
  logic clock, reset, start;
  FP_T fpuOut;
  logic done;
  condCode_t condCodes;
  opStatusFlag_t opStatusFlags;

  fpuDiv #(.FP_T(FP_T)) DUT(.*);

  task automatic doDiv
    (input FP_T in1,
     input FP_T in2);

    reset <= 0;
    #1;
    reset <= 1;
    #1;
    reset <= 0;

    fpuIn1 <= in1;
    fpuIn2 <= in2;
    start <= 1;
    @(posedge clock);
    start <= 0;

    while (~done) @(posedge clock);

    $display("Result of %h / %h = %h (%b  %b  %b).",
             fpuIn1, fpuIn2, fpuOut, fpuOut.sign, fpuOut.exp, fpuOut.frac);
  endtask

  initial begin
    reset = 1;
    reset <= 0;
    clock = 0;

    forever #10 clock = ~clock;
  end


  initial begin
    doDiv(16'h8FE3,
          16'hA3CC);
    for (int i = 0; i < 100; i++) begin
      doDiv(FP_T'($urandom), FP_T'($urandom));
    end

    repeat (2) @(posedge clock);
    $finish;
  end
endmodule : fpudiv_test
