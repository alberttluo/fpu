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

## Testing
The randomized test suite requires any version of Python3. To generate some random operations with random operands, simply run
```python
python3 autotest.py --nums=<number of operation sets>
```
Each set is a pair of operands which will be tested with all currently supported operations (add, subtract, multiply). To build the test, run
```bash
make rand
```
This generates the ```randtest``` executable, which will generate a two files:
 * One that shows the outputs of each operation.
 * One that shows all the valid, incorrect outputs. (Some wrong outputs are tolerated due to precision differences between this implementation and the IEEE754 standard).

## Progress
I finished some cleanup and all test cases are passing. I will move on to division next, which I anticipate will take quite some time to get correct. In the clean-up process, I also introduced randomized testing. **There will likely be no progress this week due to finals.**
