/*
* normalizer.sv: Normalizes floating point values based on precision type and
* operation. Currently only supports half-precision.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

module fpuNormalizer16
  (input  logic C,
   input  fp16_t unnormalizedIn,
   output fp16_t normalizedOut);

  // Leading zeros count (not including carry out).
  logic [$clog2(`FP16_FRACW + 1) - 1:0] lzc;
  
  always_comb begin
    if (unnormalizedIn.frac[`FP16_FRACW - 1:0]) lzc = 0;
    else if (unnormalizedIn.frac[`FP16_FRACW - 2:0]) lzc = 1;
    else if (unnormalizedIn.frac[`FP16_FRACW - 3:0]) lzc = 2;
    else if (unnormalizedIn.frac[`FP16_FRACW - 4:0]) lzc = 3;
    else if (unnormalizedIn.frac[`FP16_FRACW - 5:0]) lzc = 4;
    else if (unnormalizedIn.frac[`FP16_FRACW - 6:0]) lzc = 5;
    else if (unnormalizedIn.frac[`FP16_FRACW - 7:0]) lzc = 6;
    else if (unnormalizedIn.frac[`FP16_FRACW - 8:0]) lzc = 7;
    else if (unnormalizedIn.frac[`FP16_FRACW - 9:0]) lzc = 8;
    else lzc = 9;
  end

  always_comb begin
    normalizedOut.sign = unnormalizedIn.sign;
    if (C) begin
      normalizedOut.frac = unnormalizedIn.frac >> 1;
      normalizedOut.exp = unnormalizedIn.exp + 1;
    end
    else if (lzc <= unnormalizedIn.exp) begin
      normalizedOut.frac = unnormalizedIn.frac << lzc;
      normalizedOut.exp = unnormalizedIn.exp - lzc;
    end
    else begin
      normalizedOut.exp = '0;
      normalizedOut.frac = '0;
    end
  end
endmodule : fpuNormalizer16
