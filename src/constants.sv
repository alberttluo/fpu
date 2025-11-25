/*
* constants.sv: Contains type definitions and constants needed for FPU
* computation -- all based on IEEE 754.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef sv_CONSTANTS
`define sv_CONSTANTS

`define NUM_OPS    4

// Bit widths for FP16 (half-precision).
`define FP16_EXPW  5
`define FP16_FRACW 10

// Bit widths for FP32 (single-precision).
`define FP32_EXPW  8
`define FP32_FRACW 23

// Bit widths for FP64 (double-precision).
`define FP64_EXPW  11
`define FP64_FRACW 52

// Half-precision IEEE 754 float.
typedef struct packed {
  logic sign;
  logic [`FP16_EXPW - 1:0] exp;
  logic [`FP16_FRACW - 1:0] frac;
} fp16_t;

// Single-precision IEEE 754 float.
typedef struct packed {
  logic sign;
  logic [`FP32_EXPW - 1:0] exp;
  logic [`FP32_FRACW - 1:0] frac;
} fp32_t;

// Double-precision IEEE 754 float.
typedef struct packed {
  logic sign;
  logic [`FP64_EXPW - 1:0] exp;
  logic [`FP64_FRACW - 1:0] frac;
} fp64_t;

typedef enum logic[$clog2(`NUM_OPS) - 1:0] {
  FPU_ADD,
  FPU_SUB,
  FPU_MUL,
  FPU_DIV
} fpuOp_t;

typedef struct packed {
  logic sign;
  logic [1:0] leadingInt;
  logic [`FP16_EXPW - 1:0] exp;
  logic [`FP16_FRACW - 1:0] frac;
} unnorm16_t;

typedef struct packed {
  logic Z, C, N, V;
} condCode_t;

typedef struct packed {
  fp16_t largeNum;
  fp16_t smallNum;
  logic [`FP16_EXPW - 1:0] expDiff;
  fp16_t alignedSmallNum;
  logic [`FP16_FRACW:0] extSigSum;
  fp16_t unnormalizedIn;
  fp16_t normalizedOut;
  fp16_t fpuOut;
} addSubDebug_t;

`endif
