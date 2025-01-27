#!/bin/sh

cd code
./compile.sh
cd ..
cd vhdl
../python/splitbin.py ../code/startup.bin
../python/genram.py bramlower 8 8 lower.bin >bramlower.vhd
../python/genram.py bramupper 8 8 upper.bin >bramupper.vhd
rm lower.bin
rm upper.bin
echo "Generated upper and lower boot RAMs"

