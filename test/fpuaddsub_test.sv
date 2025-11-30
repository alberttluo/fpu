/*
* fpuaddsub_test.sv: A basic test bench for adding and subtracting.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "fpu_lib.sv"

module fpuaddsub_test();
  logic           sub;
  fp16_t          fpuIn1;
  fp16_t          fpuIn2;
  fpuOp_t         op; // Useless if just testing ALU operations.
  fp16_t          fpuOut;
  condCode_t      condCodes;
  opStatusFlag_t  opStatusFlags;

  fpuAddSub16 DUT(.*);

  function automatic fp16_t randNum();
    return fp16_t'($urandom);
  endfunction

  task automatic displayInfo();
    $display("fpuIn1(%b)    fpuIn2(%b)\n",
             fpuIn1, fpuIn2,
             "S1(%b)E1(%b)frac(%b)    S2(%b)E2(%b)frac(%b)\n",
             fpuIn1.sign, fpuIn1.exp, fpuIn1.frac,
             fpuIn2.sign, fpuIn2.exp, fpuIn2.frac,
             "fpuOP(%s)\n",
             op.name,
             "fpuOut(%b) (%h)\n",
             fpuOut, fpuOut,
             "ZCNV(%b)\n",
             condCodes,
             "=====================================================\n");
  endtask

  task automatic doAdd
    (input fp16_t in1,
     input fp16_t in2);

    fpuIn1 <= in1;
    fpuIn2 <= in2;
     #10;
  endtask

  initial begin
    // 20 random additions.
    sub <= 1'b0;

    for (int i = 0; i < 20; i++) begin
      doAdd(randNum(), randNum());
      #10;
    end

    // 20 random subtractions.
    sub <= 1'b1;
    for (int i = 0; i < 20; i++) begin
      doAdd(randNum(), randNum());
      #10;
    end

    $finish;
  end
endmodule : fpuaddsub_test
