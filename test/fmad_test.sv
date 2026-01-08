/*
* fmad_test.sv: Test bench for fmad operations. Currently only testing integers.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "fmad.sv"

module fmad_test();
  localparam int WIDTH = 8, OUTWIDTH = 2 * WIDTH;

  logic [WIDTH - 1:0] fmadMulIn1;
  logic [WIDTH - 1:0] fmadMulIn2;
  logic [WIDTH - 1:0] fmadAddIn;
  logic [OUTWIDTH - 1:0] fmadOut;
  logic start, clock, reset, fmadDone, sub, negate;

  fmad #(.WIDTH(WIDTH)) DUT(.*);

  task automatic doFMAD
    (input logic [WIDTH - 1:0] m1, m2, a,
     input logic s, n);
    reset <= 0;
    #1;
    reset <= 1;
    #1;
    reset <= 0;

    fmadMulIn1 <= m1;
    fmadMulIn2 <= m2;
    fmadAddIn <= a;
    sub <= s;
    negate <= n;
    start <= 1;
    @(posedge clock);
    start <= 0;

    while (~fmadDone) begin
      @(posedge clock);
    end

    $display("Result of FMAD(%d, %d, %d, %s, %s) = %d (%b)",
             m1, m2, a,  s ? "SUB" : "ADD", n ? "NEG" : "POS", $signed(fmadOut), fmadOut);
  endtask

  function automatic logic [WIDTH - 1:0] randNum();
    return WIDTH'($urandom);
  endfunction

  initial begin
    reset = 1;
    clock = 0;
    reset <= 0;

    forever #10 clock = ~clock;
  end

  initial begin
    for (int i = 0; i < 100; i++) begin
      doFMAD(randNum(), randNum(), randNum(), 0, 0);
      @(posedge clock);
      doFMAD(randNum(), randNum(), randNum(), 0, 1);
      @(posedge clock);
      doFMAD(randNum(), randNum(), randNum(), 1, 0);
      @(posedge clock);
      doFMAD(randNum(), randNum(), randNum(), 1, 1);
    end

    $finish;
  end
endmodule : fmad_test
