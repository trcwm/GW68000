#!/bin/sh

ghdl -a --std=08 ../../vhdl/sdram_ctrl_cl2.vhd
ghdl -a --std=08 sdram.vhd
ghdl -a --std=08 sdram_ctrl_tb.vhd
ghdl -e --std=08 sdram_ctrl_tb
ghdl -r --std=08 sdram_ctrl_tb --wave=sdram_ctrl_tb.ghw
