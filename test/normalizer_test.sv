`include "constants.sv"
`include "fpu_lib.sv"

module normalizer_test();
  unnorm16_t unnormalizedIn;
  fp16_t normalizedOut;

  fpuNormalizer16 DUT(.*);

  initial begin
    unnormalizedIn <= 18'b0_11_10001_0000000000;

    #10;

    unnormalizedIn <= 18'b1_01_10001_0000000000;

    #10;

    unnormalizedIn <= 18'b0_00_01000_0011111111;

    #10;

    $finish;
  end
endmodule : normalizer_test
