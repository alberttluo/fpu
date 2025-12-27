import random
import numpy as np
from argparse import ArgumentParser

FILE = "randomOps.txt"
OPS = ["ADD", "SUB", "MUL", "DIV"]

def genRandomOperands(nums: int):
    opList = []
    seenOps = set() 

    while len(seenOps) < len(OPS) * nums: 
        in1Hex = np.uint16(random.getrandbits(16))
        in2Hex = np.uint16(random.getrandbits(16))
        
        in1Float = in1Hex.view(np.float16)
        in2Float = in2Hex.view(np.float16)

        for op in OPS:
            outFloat = 0
            if (op == "ADD"):
                outFloat = in1Float + in2Float
            elif (op == "SUB"):
                outFloat = in1Float - in2Float
            elif (op == "MUL"):
                outFloat = in1Float * in2Float
            else:
                if (in2Float != 0):
                    outFloat = in1Float / in2Float

            outHex = outFloat.view(np.uint16)
            
            line = f"{in1Hex:04x} {in2Hex:04x} {op} {outHex:04x}\n"            

            if line not in seenOps:
                seenOps.add(line)
                opList.append(line)

    with open(FILE, 'w') as f:
        f.writelines(opList)
   
def main():
    parser = ArgumentParser()
    parser.add_argument('--nums', type=int, default=10)

    args = parser.parse_args()
    genRandomOperands(nums = args.nums)

if __name__ == "__main__":
    main()
