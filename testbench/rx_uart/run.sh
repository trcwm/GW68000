#!/bin/sh

ghdl -a --std=08 ../../vhdl/rx_uart.vhd
ghdl -a --std=08 ../../vhdl/baudgen.vhd
ghdl -a --std=08 rx_uart_tb.vhd
ghdl -e --std=08 rx_uart_tb
ghdl -r --std=08 rx_uart_tb --wave=rx_uart_tb.ghw

