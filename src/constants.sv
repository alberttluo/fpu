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


`endif
