#!/bin/sh

rm -f *.lst
rm -f *.bin
../asmx/asmx -e -w -b -l -C 68000 loop.asm
../asmx/asmx -e -w -b -l -C 68000 uart.asm
../asmx/asmx -e -w -b -l -C 68000 startup.asm
mv loop.asm.bin loop.bin
mv uart.asm.bin uart.bin
mv startup.asm.bin startup.bin
mv startup.asm.lst startup.lst
echo "Compiled.."
