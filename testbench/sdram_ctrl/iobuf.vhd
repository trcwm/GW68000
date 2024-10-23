-- GOWIN IOBUF simulation model for GHDL
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;

entity IOBUF is
    port
    (
        I   : in std_logic;
        O   : out std_logic;
        IO  : inout std_logic;
        OEN : in std_logic
    );
end IOBUF;

architecture rtl of IOBUF is
begin

    proc_comb: process(I, O, IO, OEN)
    begin
        if (OEN = '1') then
            IO <= 'Z';
            O <= IO;
        else
            IO <= I;
        end if;
    end process proc_comb;

end architecture rtl;
