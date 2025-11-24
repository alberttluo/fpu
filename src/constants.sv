/*
* constants.sv: Contains type definitions and constants needed for FPU
* computation -- all based on IEEE 754.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef sv_CONSTANTS
`define sv_CONSTANTS

`define NUM_OPS 6

typedef enum logic [1:0] {
  FP16,
  FP32,
  FP64
} fpuPrec_t;

typedef enum logic[$clog2(`NUM_OPS) - 1:0] {
  FPU_ADD,
  FPU_SUB,
  FPU_MUL,
  FPU_DIV,
  FPU_SHL,
  FPU_SHR,
  FPU_UNDEF1,
  FPU_UNDEF2
} fpuOp_t;

typedef struct packed {
  logic effS2;
  logic shiftIn1;
  logic [$clog2(5) - 1:0] expShift;
  logic [5 - 1:0] adjExp;
  logic [10 - 1:0] adjSig;
  logic [10 - 1:0] nonAdjSig;
  logic adjSign;
  logic nonAdjSign;
  logic [10 - 1:0] sigLarge;
  logic [10 - 1:0] sigSmall;
  logic [10:0] extSigOut;
  logic largeSign, smallSign;
} addSubDebug_t;

`endif
