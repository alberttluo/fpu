/*
* multiplier_test.sv: Testbench for sequential multipler.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "multiplier.sv"

module multiplier_test();
 logic [`FP16_FRACW:0] mulIn1;
 logic [`FP16_FRACW:0] mulIn2;
 logic start;
 logic clock, reset;
 logic [2 * `FP16_FRACW + 1:0] mulOut;
 logic done;

 fpuMultiplier16 DUT(.*);

 task automatic doMultiply
   (input logic [`FP16_FRACW:0] in1,
    input logic [`FP16_FRACW:0] in2);
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

   $display("Result of %d (%b) * %d (%b) = %d (%b)\n",
            in1, in1, in2, in2, mulOut, mulOut);
 endtask

 initial begin
   reset = 1;
   reset <= 0;
   clock = 0;
   forever #10 clock = ~clock;
 end

 initial begin
  // $monitor("mulIn1 = %b, mulIn2 = %b, mulOut = %b\n",
  //          mulIn1, mulIn2, mulOut,
  //          "storedIn2 = %b\n",
  //          DUT.storedIn2,
  //          "start = %b, reset = %b, done = %b\n",
  //          start, reset, done,
  //          "compEn = %b, compDone = %b\n",
  //          DUT.compEn, DUT.compDone,
  //          "currState = %s, nextState = %s\n",
  //          DUT.FSM.currState.name, DUT.FSM.nextState.name,
  //          "===============================================\n");

   doMultiply(11'd3, 11'd4);
   doMultiply(11'd19, 11'd47);
   doMultiply(11'd1, 11'd4);
   doMultiply(11'd0, 11'd47);
   doMultiply(11'd999, 11'd35);
   doMultiply(11'd1234, 11'd1278);
   doMultiply(11'b11111111111, 11'b11111111111);
   $finish;
 end
endmodule : multiplier_test
