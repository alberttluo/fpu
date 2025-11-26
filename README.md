# FPU (Floating Point Unit)
An implementation of an IEEE754-compliant floating point unit, written in SystemVerilog. Theoretically, this FPU should support arbitrary floating point precision types, such as Google's [bfloat](https://en.wikipedia.org/wiki/Bfloat16_floating-point_format). Currently, there is no support for any specific architecture.

Maintainer(s) and Author(s): Albert Luo albertlu@cmu.edu

## Status
I am currently working on fixing the normalization unit to do rounding. Additionally, some condition codes are not properly set. There is no extensive testbench, but brief stress testing shows that addition/subtraction, multiplication, and comparisons are all functionally correct (disregarding rounding). The hardest part is yet to come...division...
