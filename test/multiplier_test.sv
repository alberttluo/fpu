/*
* multiplier_test.sv: Testbench for sequential multipler.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "multiplier.sv"

module multiplier_test();
 logic [`FP16_FRACW - 1:0] mulIn1;
 logic [`FP16_FRACW - 1:0] mulIn2;
 logic start;
 logic clock, reset;
 logic [2 * `FP16_FRACW - 1:0] mulOut;
 logic done;

 initial begin
   reset = 0;
   reset <= 1;
   clock = 0;
   forever #10 clock = ~clock;
 end

 initial begin
   mulIn1 <= 10'd3;
   mulIn2 <= 10'd4;
   start <= 1;

   #6000000;

   $finish;
 end

 fpuMultiplier16 DUT(.*);
endmodule : multiplier_test
