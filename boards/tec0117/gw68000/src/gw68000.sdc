//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.02 
//Created Time: 2024-10-19 22:43:33
create_clock -name clk100M -period 10 -waveform {0 5} [get_ports {clk100M}]
create_generated_clock -name clk12M5 -source [get_ports {clk100M}] -master_clock clk100M -divide_by 8 [get_nets {clk12M5}]
