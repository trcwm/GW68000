#!/bin/sh

rm *.lst
rm *.bin
rm *.txt
../asmx/asmx -e -w -b -l -C 68000 loop.asm
../asmx/asmx -e -w -b -l -C 68000 uart.asm
#mv loop.asm.bin loop.bin
#mv loop.asm.lst loop.lst
#mv uart.asm.bin uart.bin
#mv uart.asm.lst uart.lst
#../tools/build/splitbin loop.bin
#../tools/build/splitbin uart.bin

