#!/bin/sh

ghdl -a -fsynopsys -fexplicit ../contrib/TG68.vhd
ghdl -a -fsynopsys -fexplicit ../contrib/TG68_fast.vhd
ghdl -a -fsynopsys -fexplicit ../vhdl/gw68000_top.vhd
ghdl -a gw68000_tb.vhd
ghdl -e gw68000_tb
ghdl -r gw68000_tb --wave=gw68000_tb.ghw
