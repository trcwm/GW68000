#!/usr/bin/python3
# Generate RAM with contents
# Copyright Moseley Instruments 2025
# Niels A. Moseley

import sys
import argparse

template = """
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ###NAME### is
    generic
    (
        data_width  : integer := ###DWIDTH###;
        addr_width  : integer := ###AWIDTH###
    );
    port
    (   
        clk         : in std_logic;
        we_n        : in std_logic;
        data_in     : in std_logic_vector(data_width-1 downto 0);
        data_out_r  : out std_logic_vector(data_width-1 downto 0);
        address     : in std_logic_vector(addr_width-1 downto 0)
    );
end ###NAME###;

architecture behavioral of ###NAME### is
    constant num_entries : integer := 2**addr_width;
    type ram_t is array(0 to num_entries-1) of std_logic_vector(data_in'range);

    function init_ram return ram_t is
        variable result : ram_t;
    begin
###CONTENTS###
        return result;
    end init_ram;

    signal RAM : ram_t := init_ram;
begin

    proc_clk: process(clk)
        variable ram_index : integer;
    begin
        if rising_edge(clk) then
            ram_index := to_integer(unsigned(address));
            if we_n = '0' then
                RAM(ram_index) <= data_in;
                data_out_r <= data_in;
            else
                data_out_r <= RAM(ram_index);
            end if;
        end if; -- rising edge
    end process proc_clk;

end behavioral;

"""


parser = argparse.ArgumentParser(description="Generate a VHDL RAM with inline contents",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument("name", help="RAM entity name")
parser.add_argument("awidth", help="address bus width in bits")
parser.add_argument("dwidth", help="data bus width in bits")
parser.add_argument("src", help="ram contents file")
args = parser.parse_args()
config = vars(args)
#print(config)

template = template.replace("###NAME###", config["name"])
template = template.replace("###DWIDTH###", config["dwidth"])
template = template.replace("###AWIDTH###", config["awidth"])

with open(config["src"], "rb") as infile:
    data = bytearray(infile.read())

    contents = ""
    idx = 0
    for i in data:
        contents = contents + f"        result({idx}) := x\"{data[idx]:02x}\";\n"
        idx=idx+1
    
template = template.replace("###CONTENTS###", contents);

print(template)
