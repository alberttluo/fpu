/*
* fpu_addsub.sv: Performs FPU addition/subtraction, given both inputs broken
* down into their sign, exponent, and mantissa parts. (done by FPU top module).
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/
`default_nettype none

module fpuAddSub
  (input  logic                         sub, // 1 for subtraction, 0 for addition
   input  logic [`BIT_WIDTH - 1:0]      fpuAddSubIn1, fpuAddSubIn2,
   input  logic                         fpuAddSubS1, fpuAddSubS2, // Signs.
   input  logic [`EXP_WIDTH - 1:0]      fpuAddSubE1, fpuAddSubE2, // Exponents.
   input  logic [`MANTISSA_WIDTH - 1:0] fpuAddSubM1, fpuAddSubM2, // Mantissas.
   output logic [`BIT_WIDTH - 1:0]      fpuAddSubOut,
   output logic [3:0]                   condCodes);

  logic                            maxExpIn; // 1 if E1 > E2, 0 otherwise.
  logic [$clog2(`EXP_WIDTH) - 1:0] expShift; // Amount by which to right shift to align points.
  logic [`MANTISSA_WIDTH:0]        fpuInAdjustedMSigned; // Signed, adjusted mantissa.
  logic [`MANTISSA_WIDTH:0]        fpuAddSubOutSignedM; // Output signed mantissa.

  assign maxExpIn = (fpuAddSubE1 > fpuAddSubE2);
  assign expShift = (maxExpIn) ? (fpuAddSubIn2 - fpuAddSubIn1) : (fpuAddSubIn1 - fpuAddSubIn2);
  assign fpuInAdjustedMSigned = (maxExpIn) ? {fpuAddSubS1, fpuAddSubM2 >> expShift} :
                                             {fpuAddSubS2 ^ sub, fpuAddSubM1 >> expShift};
  assign fpuAddSubOutSignedM = (maxExpIn) ? ({fpuAddSubS1, fpuAddSubIn1} + fpuInAdjustedMSigned) :
                                             ({fpuAddSubS2, fpuAddSubIn2} + fpuInAdjustedMSigned);

  // TODO: Implement renormalization + condCodes.

  assign fpuAddSubOut = {fpuAddSubOutSignedM[`MANTISSA_WIDTH],
                         maxExpIn ? fpuAddSubE1 : fpuAddSubE2,
                         fpuAddSubOutSignedM[`MANTISSA_WIDTH - 1:0]};
endmodule : fpuAddSub
