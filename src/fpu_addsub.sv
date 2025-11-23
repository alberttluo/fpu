/*
* fpu_addsub.sv: Performs FPU addition/subtraction, given both inputs broken
* down into their sign, exponent, and mantissa parts. (done by FPU top module).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/
`default_nettype none

/*
* Inputs:
*   sub               : 1 for substraction, 0 for addition
*   fpuAddSubIn{1,2}  : Operands
*   fpuAddSubS{1,2}   : Sign bits for operands.
*   fpuAddSubE{1,2}   : Exponent bits for operands
*   fpuAddSubSig{1,2} : Explicit significands for operands
*
* Outputs:
*   fpuAddSubOut : Result of the operation (either addition or subtraction).
*   condCodes    : Condition codes (set normally).
*
*/
module fpuAddSub
  #(parameter int BIT_WIDTH = 16,
              int EXP_WIDTH = 5,
              int SIG_WIDTH = 10)
  (input  logic                   sub,
   input  logic [BIT_WIDTH - 1:0] fpuAddSubIn1, fpuAddSubIn2,
   input  logic                   fpuAddSubS1, fpuAddSubS2,
   input  logic [EXP_WIDTH - 1:0] fpuAddSubE1, fpuAddSubE2,
   input  logic [SIG_WIDTH - 1:0] fpuAddSubSig1, fpuAddSubSig2,
   output logic [BIT_WIDTH - 1:0] fpuAddSubOut,
   output logic [3:0]             condCodes);

  // Explicit condition codes for carry, overflow, negative, and zero.
  logic C, V, N, Z;

  // Effective sign bit for operand 2 -- turns subtractions into additions by
  // flipping the sign bit.
  logic effS2;
  assign effS2 = fpuAddSubIn2 ^ sub;

  // 1 if E1 < E2, 0 otherwise.
  logic shiftIn1;

  // Amount by which to right shift to align points.
  logic [$clog2(EXP_WIDTH) - 1:0] expShift;

  // Adjusted and non-adjusted significands/signs.
  logic [SIG_WIDTH - 1:0] adjSig;
  logic adjSign;

  logic [SIG_WIDTH - 1:0] nonAdjSig;
  logic nonAdjSign;

  // Output significand.
  logic [SIG_WIDTH - 1:0] outSig;
  logic outS;

  // Final opearands after adjustments, split by magnitude.
  logic [SIG_WIDTH - 1:0] sigLarge;
  logic [SIG_WIDTH - 1:0] sigSmall;

  // Extended output significand.
  logic [SIG_WIDTH:0] extSigOut;

  // Signs of large and small operands.
  logic largeSign, smallSign;

  // Output sign.
  logic outSign;

  // Right shift the smaller exponent by the difference in exponents.
  assign shiftIn1  = (fpuAddSubE1 < fpuAddSubE2);
  assign expShift  = (shiftIn1) ? (effS2 - fpuAddSubIn1) : (fpuAddSubIn1 - effS2);
  assign {adjSign, adjSig} = (shiftIn1) ? {fpuAddSubS1, fpuAddSubSig1 >> expShift} :
                                          {effS2, fpuAddSubSig2 >> expShift};
  assign {nonAdjSign, nonAdjSig} = (shiftIn1) ? {effS2, fpuAddSubSig2} :
                                                   {fpuAddSubS1, fpuAddSubSig1};

  // Assign large/small operands based on magnitude.
  always_comb begin
    if (adjSig > nonAdjSig) begin
      sigLarge = adjSig;
      largeSign = adjSign;
      sigSmall = nonAdjSig;
      smallSign = nonAdjSign;
    end
    else begin
      sigLarge = nonAdjSig;
      largeSign = nonAdjSign;
      sigSmall = adjSig;
      smallSign = adjSign;
    end
  end

  // Add or subtract magnitudes based on signs.
  always_comb begin
    if (largeSign == smallSign) begin
      extSigOut = {1'b0, sigLarge} + {1'b0, sigSmall};
      outSign = largeSign;
    end
    else begin
      extSigOut = {1'b0, sigLarge} - {1'b0, sigSmall};
      outSign = largeSign;
    end
  end

  assign extSigOut = sigLarge + sigSmall;
  assign C = extSigOut[SIG_WIDTH];

  // Overflow if addition of two positives is negative, or subtraction of two
  // negatives is positive.
  assign V = (~sub & ~extOpS1 & ~extOpS2 & outS) | (sub & extOpS2 & extOpS2 & ~outS);
  assign Z = (outS == '0);
  assign N = outS;

  // TODO: Implement normalization.

endmodule : fpuAddSub
