/*
* divider_test.sv: Testbench for restoring (integer) division.
*
* Author: Albert Luo (albertlu)
*/

`include "divider.sv"

module divider_test();
  localparam int WIDTH = 8;

  logic [WIDTH - 1:0] divIn1;
  logic [WIDTH - 1:0] divIn2;
  logic start, clock, reset;
  logic [WIDTH - 1:0] divOut;
  logic [WIDTH - 1:0] divRem;
  logic done;

  fpuDivider #(.WIDTH(WIDTH)) DUT(.*);

  task automatic doDiv
    (input logic [WIDTH - 1:0] in1,
     input logic [WIDTH - 1:0] in2);

    reset <= 0;
    #1;
    reset <= 1;
    #1;
    reset <= 0;

    start <= 1;
    divIn1 <= in1;
    divIn2 <= in2;
    @(posedge clock);
    start <= 0;

    while (~done) @(posedge clock);

    $display("Result of %d (%b) / %d (%b) = %d (%b) with remainder %d (%b).",
             divIn1, divIn1, divIn2, divIn2, divOut, divOut, divRem, divRem);
    assert(divOut == divIn1 / divIn2) else $display("Wrong answer.");
  endtask

  function automatic logic [WIDTH - 1:0] randNum();
    return WIDTH'($urandom);
  endfunction

  initial begin
    reset = 1;
    reset <= 0;
    clock = 0;

    forever #10 clock = ~clock;
  end

  initial begin
    // $monitor("divIn1(%d) divIn2(%d) divOut(%b)\n",
    //          divIn1, divIn2, divOut,
    //          "currState = %s, nextState = %s\n",
    //          DUT.FSM.currState, DUT.FSM.nextState);
    for (int i = 0; i < 100; i++) begin
      doDiv(randNum(), randNum());
    end

    $finish;
  end
endmodule : divider_test
