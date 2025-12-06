/*
* randtest.sv: A randomized testbench for all currently supported operations,
* verified against Numpy.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "fpu_lib.sv"

module fpuRandTest();
  // fpu16 signals.
  fp16_t       fpuIn1, fpuIn2;
  fpuOp_t      op;
  logic        clock, reset, start;
  logic        mulDone;
  fp16_t       fpuOut;
  condCode_t   condCodes;
  statusFlag_t statusFlags;
  fpuComp_t    comps;

  // File descriptors.
  int inFD;
  int outFD;
  int outWrongFD;

  string outputFormat = "%s %s (expected %h, got %h) ---- NV(%b) DZ(%b) OF(%b) UF(%b) NX(%b)\n";

  fpu16 DUT(.*);

  // Helper task to write computed result to output file.
  task automatic writeOutput
    (input string line,
     input fp16_t expected);
    logic correct = (fpuOut == expected);

    $fwrite(outFD, outputFormat,
            line, correct ? "CORRECT" : "WRONG", expected, fpuOut,
            statusFlags.NV, statusFlags.DZ, statusFlags.OF, statusFlags.UF, statusFlags.NX);

    // Only care about valid, but wrong results. 
    if (!correct && !statusFlags.NV)
      $fwrite(outWrongFD, outputFormat,
              line, "WRONG", expected, fpuOut,
              statusFlags.NV, statusFlags.DZ, statusFlags.OF, statusFlags.UF, statusFlags.NX);
  endtask

  // Multiplication helper test (waits for multiplication to be finished).
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
    op <= FPU_MUL;
    start <= 1;
    @(posedge clock);
    start <= 0;

    while (~mulDone) @(posedge clock);

    // For sanity.
    repeat (2) @(posedge clock);
  endtask

  // Addition helper.
  task automatic doAdd
    (input fp16_t in1,
     input fp16_t in2);

    fpuIn1 <= in1;
    fpuIn2 <= in2;
    op <= FPU_ADD;

    // Hold result for two clock cycles.
    repeat (2) @(posedge clock);
  endtask

  // Subtraction helper.
  task automatic doSub
    (input fp16_t in1,
     input fp16_t in2);

    fpuIn1 <= in1;
    fpuIn2 <= in2;
    op <= FPU_SUB;

    // Hold result for two clock cycles.
    repeat (2) @(posedge clock);
  endtask

  // Clocking block.
  initial begin
    clock = 0;
    reset = 1;
    #20;
    reset = 0;
    forever #10 clock = ~clock;
  end

  string opStr, line;
  logic [15:0] in1;
  logic [15:0] in2;
  fp16_t expected;

  initial begin
    inFD = $fopen("randomOps.txt", "r");
    outFD = $fopen("randtestOutput.txt", "w");
    outWrongFD = $fopen("randtestOutputWrong.txt", "w");

    // Check that files are valid and opened correctly.
    if (inFD == 0) begin
      $fatal("Failed to open input file.\n");
    end

    if (outFD == 0) begin
      $fclose(inFD);
      $fatal("Failed to open output file.\n");
    end

    if (outWrongFD == 0) begin
      $fclose(inFD);
      $fclose(outFD);
      $fatal("Failed to open output (wrong) file.\n");
    end

    // Parse input file and perform operations.
    while ($fscanf(inFD, "%h %h %s %h\n", in1, in2, opStr, expected) == 4) begin
      line = $sformatf("%h %h %s %h", in1, in2, opStr, expected);

      if (opStr == "ADD") begin
        doAdd(in1, in2);
      end
      else if (opStr == "SUB") begin
        doSub(in1, in2);
      end
      else begin
        doMultiply(in1, in2);
      end

      if (fpuOut != expected) begin
        $display("Wrong result for %h %h %s (expected %h, got %h)",
                 in1, in2, opStr, expected, fpuOut);
      end

      writeOutput(line, expected);
    end

    $fclose(inFD);
    $fclose(outFD);
    $fclose(outWrongFD);
    $finish;
  end
endmodule : fpuRandTest
