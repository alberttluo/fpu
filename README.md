# FPU (Floating Point Unit)
An implementation of an IEEE754-compliant floating point unit, written in SystemVerilog. Theoretically, this FPU should support arbitrary floating point precision types, such as Google's [bfloat](https://en.wikipedia.org/wiki/Bfloat16_floating-point_format). Currently, there is no support for any specific architecture.

Maintainer(s) and Author(s): Albert Luo albertlu@cmu.edu

## Status
I am currently working on getting the condition codes set properly and adding support for NaNs. Check out the 'fix/condcodes' branch for more updates. This should be a relatively quick fix. 
