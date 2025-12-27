/*
* fpu_div.sv: A floating point division coprocessor.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`include "constants.sv"
`include "divider.sv"
`include "fpu_lib.sv"

typedef enum logic [1:0] {
  FPDIV_WAIT,
  FPDIV_SIGCOMP,
  FPDIV_DONE
} fpuDivState_t;

module fpuDiv
  #(parameter type FP_T = fp16_t)
  (input  FP_T           fpuIn1, fpuIn2,
   input  logic          clock, reset, start,
   output FP_T           fpuOut,
   output logic          done,
   output condCode_t     condCodes,
   output opStatusFlag_t opStatusFlags);

  localparam int EXPW = $bits(FP_T.exp);
  localparam int FRACW = $bits(FP_T.frac);
endmodule : fpuDiv

module fpuDivFSM
  (input  logic start, sigDivDone,
   input  logic clock, reset,
   output logic done);
endmodule : fpuDivFSM
