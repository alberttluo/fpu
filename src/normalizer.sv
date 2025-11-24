/*
* normalizer.sv: Normalizes floating point values based on precision type and
* operation. Currently only supports half-precision.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

module fpuNormalizer
  #(parameter int BIT_WIDTH = 16,
              int EXP_WIDTH = 5,
              int SIG_WIDTH = 10)
  (input  fpuOp_t op,
   input  logic [SIG_WIDTH:0]     extSigOut,
   input  logic [EXP_WIDTH - 1:0] adjExp,
   output logic [SIG_WIDTH:0]     normSig,
   output logic [EXP_WIDTH - 1:0] normExp,
   output logic                   V);

  // Number of leading zeros (if normSig < 1).
  logic [$clog2(SIG_WIDTH) - 1:0] lzc;

  // Top bit of the adjusted exponent -- used for overflow calculation.
  logic expTop;
  assign expTop = adjExp[EXP_WIDTH - 1];

  always_comb begin
    normSig = extSigOut;
    normExp = adjExp;

    // sigOut = 0 case (output is 0).
    if (extSigOut == '0) begin
      normSig = '0;
      normExp = '0;
    end
    // sigOut >= 2 case.
    else if (extSigOut[SIG_WIDTH]) begin
      normSig = normSig >> '1;
      normExp = normExp + '1;
    end
    // 0 < normSig <= 2, but possibly < 1.
    else begin
      // TODO: lzc for arbitrary bit width.
      if (normSig[SIG_WIDTH - 1]) lzc = 0;
      else if (normSig[SIG_WIDTH - 2]) lzc = 1;
      else if (normSig[SIG_WIDTH - 3]) lzc = 2;
      else if (normSig[SIG_WIDTH - 4]) lzc = 3;
      else if (normSig[SIG_WIDTH - 5]) lzc = 4;
      else if (normSig[SIG_WIDTH - 6]) lzc = 5;
      else if (normSig[SIG_WIDTH - 7]) lzc = 6;
      else if (normSig[SIG_WIDTH - 8]) lzc = 7;
      else if (normSig[SIG_WIDTH - 9]) lzc = 8;
      else lzc = 9;

      normSig = normSig << lzc;

      // Could cause overflow.
      normExp = normExp - lzc;
    end
  end

  assign V = (expTop ^ normExp[EXP_WIDTH - 1]);
endmodule : fpuNormalizer
