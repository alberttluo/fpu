/*
* fpumul_test.sv: Testbench for floating point multiplier.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "multiplier.sv"

module fpumul_test();
 fp16_t       fpuIn1;
 fp16_t       fpuIn2;
 fp16_t       fpuOut;
 logic        start;
 logic        clock, reset;
 logic        done;
 condCode_t   condCodes;
 opStatusFlag_t opStatusFlags;

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

 function automatic fp16_t randNum();
   return fp16_t'($urandom);
 endfunction

 initial begin
   reset = 1;
   reset <= 0;
   clock = 0;
   forever #10 clock = ~clock;
 end

 initial begin
   $monitor("fpuIn1(%h) fpuIn2(%h)\n",
            fpuIn1, fpuIn2,
            "sigMulOutInt(%b) unnormExp(%b) sigMulOutFrac(%b)\n",
            DUT.sigMulOutInt, DUT.unnormExp, DUT.sigMulOutFrac,
            "fpuOut = %h\n",
            fpuOut,
            "currState = %s, nextState = %s\n",
            DUT.FSM.currState.name, DUT.FSM.nextState.name,
            "sigMulOutInt(%b), sigMulOutFrac(%b)\n",
            DUT.sigMulOutInt, DUT.sigMulOutFrac);

   // 100 random multiplications.

   for (int i = 0; i < 100; i++) begin
     doMultiply(randNum(), randNum());
   end
   $finish;
 end
endmodule : fpumul_test
