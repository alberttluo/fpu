`include "constants.sv"
`include "fpu_lib.sv"

module normalizer_test();
  localparam int EFW = 11;

  logic unnormSign;
  logic [1:0] unnormInt;
  logic [EFW - 1:0] unnormFrac;
  logic [`FP16_EXPW - 1:0] unnormExp;
  logic sticky;
  fp16_t normOut;

  fpuNormalizer16 #(.EFW(EFW)) DUT(.*);

  initial begin
    {unnormSign, unnormInt, unnormExp, unnormFrac} <= 19'b0_11_10001_00000000000;

    #10;

    {unnormSign, unnormInt, unnormExp, unnormFrac} <= 19'b1_01_10001_00000000000;

    #10;

    {unnormSign, unnormInt, unnormExp, unnormFrac} <= 19'b0_00_01000_00111111111;

    #10;

    $finish;
  end
endmodule : normalizer_test
