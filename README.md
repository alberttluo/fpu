# FPU (Floating Point Unit)
An implementation of a floating point unit, with better precision than allowed by the IEEE754 standard, written in SystemVerilog. When completed, the FPU will support arbitrary floating point precision types, such as Google's [bfloat](https://en.wikipedia.org/wiki/Bfloat16_floating-point_format). Currently, there is no support for any specific architecture.

Maintainer(s) and Author(s): Albert Luo albertlu@cmu.edu

## Operations
This implementation will, when completed, support the following operations.
  * Addition
  * Subtraction
  * Multiplication
  * Division
  * Square Root
  * Fused Multiply-Add 
  * Fused Multiply-Subtract
  * Minimum/Maximum
  * Comparisons
  * Conversions between integers and other float formats

For now, all computations are rounded with 'round to nearest, ties to even'.

## Status Flags
All IEEE754 status flags are supported. They are
  * NV (Invalid)
  * DZ (Division by Zero)
  * OF (Overflow)
  * UF (Underflow)
  * NX (Inexact)

The negative (N) and zero (Z) condition codes are also supported, though this is not according the IEEE754 protocol.

## Progress
I am currently working on some cleanup. There are some scattered bugs that should be fixed relatively quickly. More specifically, they have to do with the aligner, which must account for the difference in exponent calculation between denormalized and normalized floats. Besides that, all the basic operations, except division, have been implemented and tested (not thoroughly). Check out the [fix/cleanup](https://github.com/alberttluo/fpu/tree/fix/cleanup) branch for more up-to-date progress. 
