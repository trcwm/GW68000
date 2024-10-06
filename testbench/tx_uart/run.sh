#!/bin/sh

ghdl -a --std=08 ../../vhdl/tx_uart.vhd
ghdl -a --std=08 tx_uart_tb.vhd
ghdl -e --std=08 tx_uart_tb
ghdl -r --std=08 tx_uart_tb --wave=tx_uart_tb.ghw
