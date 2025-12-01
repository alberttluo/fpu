# FPU (Floating Point Unit)
An implementation of an IEEE754-compliant floating point unit, written in SystemVerilog. Theoretically, this FPU should support arbitrary floating point precision types, such as Google's [bfloat](https://en.wikipedia.org/wiki/Bfloat16_floating-point_format). Currently, there is no support for any specific architecture.

Maintainer(s) and Author(s): Albert Luo albertlu@cmu.edu

## Status
I am currently working on some cleanup. There are some scattered bugs that should be fixed relatively quickly. More specifically, they have to do with the aligner, which must account for the difference in exponent calculation between denormalized and normalized floats. Besides that, all the basic operations, except division, have been implemented and tested (not thoroughly). Check of the 'fix/cleanup' branch for more up-to-date progress. 
