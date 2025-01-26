# GW68000 - a GOWIN FPGA based 68000 system

A Retrochallenge 2024/10 project.

## Status
* TG68 core works.
* block ram memory works.
* tx uart works at 115200 baud.
* rx uart works at 115200 baud.

## TODO
* embedded SDRAM controller.
* S-record upload for booting.
* external storage support.
* timer with interrupt.
* get Fuzix running.

## Building
* execute 'bootstrap.sh' to generate the blockram VHDL files.
* use Quartus II 13 to build for the Terasic DE0 board.
