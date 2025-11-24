/*
* fpu_addsub.sv: Performs FPU addition/subtraction, given both inputs broken
* down into their sign, exponent, and mantissa parts. (done by FPU top module).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/
`default_nettype none

`include "constants.sv"

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
   output logic [3:0]             condCodes,
   // All internal signals for debugging.
   output addSubDebug_t           addSubView);

  // Explicit condition codes.
  logic Z, C, N, V;
  assign condCodes = {Z, C, N, V};

  // Effective sign bit for operand 2 -- turns subtractions into additions by
  // flipping the sign bit.
  logic effS2;
  assign effS2 = fpuAddSubS2 ^ sub;

  // 1 if E1 < E2, 0 otherwise.
  logic shiftIn1;

  // Amount by which to right shift to align points.
  logic [$clog2(EXP_WIDTH) - 1:0] expShift;
  logic [EXP_WIDTH - 1:0] adjExp;

  // Adjusted and non-adjusted significands/signs.
  // Note that adjusted means the one that we are not "adjusting".
  logic [SIG_WIDTH:0] adjSig;
  logic [SIG_WIDTH:0] nonAdjSig;
  logic adjSign;
  logic nonAdjSign;

  // Final opearands after adjustments, split by magnitude.
  logic [SIG_WIDTH:0] sigLarge;
  logic [SIG_WIDTH:0] sigSmall;

  // Extended significands.
  logic [SIG_WIDTH:0] extSig1;
  logic [SIG_WIDTH:0] extSig2;
  logic [SIG_WIDTH:0] extSigOut;
  
  // Normalized fields.
  logic [SIG_WIDTH:0] normSig;
  logic [EXP_WIDTH - 1:0] normExp;

  // Signs of large and small operands.
  logic largeSign, smallSign;

  // Right shift the smaller exponent by the difference in exponents.
  assign shiftIn1  = (fpuAddSubE1 < fpuAddSubE2);

  // Attach leading one to significands.
  assign extSig1 = {1'b1, fpuAddSubSig1};
  assign extSig2 = {1'b1, fpuAddSubSig2};

  always_comb begin
    if (shiftIn1) begin
      expShift = (fpuAddSubE2 - fpuAddSubE1);
      adjExp = fpuAddSubE2;
      {adjSign, adjSig} = {effS2, extSig2};
      {nonAdjSign, nonAdjSig} = {fpuAddSubS1, extSig1 >> expShift};
    end
    else begin
      expShift = (fpuAddSubE1 - fpuAddSubE2);
      adjExp = fpuAddSubE1;
      {adjSign, adjSig} = {fpuAddSubS1, extSig1};
      {nonAdjSign, nonAdjSig} = {effS2, extSig2 >> expShift};
    end
  end

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
      extSigOut = sigLarge + sigSmall;
    end
    else begin
      extSigOut = sigLarge - sigSmall;
    end
  end

  // Set condition codes. Overflow flag is set by normalizer.
  assign C = extSigOut[SIG_WIDTH];
  assign Z = (extSigOut == '0);
  assign N = largeSign;

  // Normalize all fields.
  fpuNormalizer #(.BIT_WIDTH(BIT_WIDTH), .EXP_WIDTH(EXP_WIDTH), .SIG_WIDTH(SIG_WIDTH))
                addSubNormalizer(.op(FPU_ADD), .extSigOut, .adjExp, .normSig,
                                 .normExp, .V);

  assign fpuAddSubOut = {largeSign, normExp, normSig[SIG_WIDTH - 1:0]};

  // assign addSubView = {effS2, shiftIn1, expShift, adjExp, adjSig, nonAdjSig, adjSign, nonAdjSign,
  //                      sigLarge, sigSmall, extSigOut, largeSign, smallSign};
endmodule : fpuAddSub
