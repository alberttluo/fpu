/*
* fpumul_test.sv: Testbench for floating point multiplier.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "multiplier.sv"

module fpumul_test();
 fp16_t fpuIn1;
 fp16_t fpuIn2;
 fp16_t fpuOut;
 logic start;
 logic clock, reset;
 logic done;
 condCode_t condCodes;

 fpuMul16 DUT(.*);

 task automatic doMultiply
   (input fp16_t in1,
    input fp16_t in2);
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

   $display("Result of %b (%h) * %b (%h) = %b (%h)\n",
            in1, in1, in2, in2, fpuOut, fpuOut);
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

   doMultiply(16'h3C00, 16'h3C00);
   $finish;
 end
endmodule : fpumul_test
