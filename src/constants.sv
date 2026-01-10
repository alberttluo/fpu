/*
* constants.sv: Contains type definitions and constants needed for FPU
* computation -- all based on IEEE 754.
*
* Author: Albert Luo (albertlu at cmu dot edu)
*/

`ifndef sv_CONSTANTS
`define sv_CONSTANTS

`define NUM_OPS      8 

// Bit widths for FP16 (half-precision).
`define FP16_EXPW    5
`define FP16_FRACW   10
`define FP16_NAN     16'h7E00

// Bit widths for FP32 (single-precision).
`define FP32_EXPW    8
`define FP32_FRACW   23
`define FP32_NAN     32'h7F800000

// Bit widths for FP64 (double-precision).
`define FP64_EXPW    11
`define FP64_FRACW   52
`define FP64_NAN     64'h3FF8000000000000

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

typedef enum logic[$clog2(`NUM_OPS + 1) - 1:0] {
  FPU_ADD,
  FPU_SUB,
  FPU_MUL,
  FPU_DIV,
  FPU_FMAD,
  FPU_FMS,
  FPU_FNMAD,
  FPU_FNMS
} fpuOp_t;

typedef struct packed {
  logic Z, C, N, V;
} condCode_t;

typedef struct packed {
  logic NV, DZ, OF, UF, NX;
} statusFlag_t;

typedef struct packed {
  logic OF, UF, NX;
} opStatusFlag_t;

typedef struct packed {
  logic lt, eq, gt;
} fpuComp_t;
`endif
