#!/usr/bin/python3

# Split 16 bit file into two 8 bit files
# Copyright Moseley Instruments 2025
# Niels A. Moseley

import sys
import argparse

parser = argparse.ArgumentParser(description="SPlit 16 bit binary into 8 bit binaries",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument("src", help="input source name")
args = parser.parse_args()
config = vars(args)

with open(config["src"], "rb") as infile:
    data = bytearray(infile.read())

    f_upper = open("upper.bin", "wb")
    f_lower = open("lower.bin", "wb")

    contents = ""
    idx = 0
    for byte in data:
        if idx % 2 == 0:
            f_upper.write(byte.to_bytes())
        else:
            f_lower.write(byte.to_bytes())
        idx=idx+1

print(f"Processed {idx} bytes")
