#!/bin/sh

ghdl -a -fsynopsys -fexplicit --std=08 ../contrib/TG68.vhd
ghdl -a -fsynopsys -fexplicit --std=08 ../contrib/TG68_fast.vhd
ghdl -a -fsynopsys -fexplicit --std=08 ../vhdl/blockram.vhd
ghdl -a -fsynopsys -fexplicit --std=08 ../vhdl/baudgen.vhd
ghdl -a -fsynopsys -fexplicit --std=08 ../vhdl/tx_uart.vhd
ghdl -a -fsynopsys -fexplicit --std=08 ../vhdl/rx_uart.vhd
ghdl -a -fsynopsys -fexplicit --std=08 ../vhdl/sdram_ctrl_cl2.vhd
ghdl -a -fsynopsys -fexplicit --std=08 ../vhdl/clkgen.vhd
ghdl -a -fsynopsys -fexplicit --std=08 ../vhdl/persistence.vhd
ghdl -a -fsynopsys -fexplicit --std=08 ../vhdl/gw68000_top.vhd
ghdl -a -fsynopsys -fexplicit --std=08 gw68000_tb.vhd
ghdl -e -fsynopsys -fexplicit --std=08 gw68000_tb
ghdl -r -fsynopsys -fexplicit --std=08 gw68000_tb --wave=gw68000_tb.ghw
