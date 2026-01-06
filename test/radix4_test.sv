/*
* radix4_test.sv: Testing the radix-4 multiplier.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "multiplier.sv"

module radix4_test();
  localparam int FRACW = 10;
  localparam int WIDTH = FRACW + 1;
  localparam int OUTW = (WIDTH << 1);

  logic [WIDTH - 1:0] mulIn1, mulIn2;
  logic clock, reset, start;
  logic [OUTW - 1:0] mulOut;
  logic done;

  radix4Mult32 #(.FRACW(FRACW)) DUT(.*);

  initial begin
    reset = 1;
    reset <= 0;
    clock = 0;
    forever #10 clock = ~clock;
  end

  task automatic doMultiply
    (input logic [WIDTH - 1:0] in1,
     input logic [WIDTH - 1:0] in2);

    reset <= 0;
    #1;
    reset <= 1;
    #1;
    reset <= 0;

    mulIn1 <= in1;
    mulIn2 <= in2;
    start <= 1;
    @(posedge clock);
    start <= 0;

    while (~done) @(posedge clock);

    $display("Result of %d (%b) * %d (%b) = %d (%b)",
             in1, in1, in2, in2, mulOut, mulOut);
  endtask

  initial begin
    // $monitor("mulIn1 = %d   mulIn2 = %d\n",
    //          mulIn1, mulIn2,
    //          "radixBits = %b   currPP = %d\n",
    //          DUT.radixBits, DUT.currPP,
    //          "shiftReg = %b\n",
    //          DUT.storedMultiplier_shiftReg);

    doMultiply(10, 2);
    doMultiply(48, 52);
    doMultiply(7, 99);
    for (int i = 0; i < 10; i++) begin
      doMultiply($urandom, $urandom);
    end
    $finish;
  end
endmodule : radix4_test
