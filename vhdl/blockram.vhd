-- Configurable block RAM
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BlockRAM is
    generic
    (
        data_width : integer := 16; -- data bus width in bits
        addr_width : integer := 8   -- address bus width in bits
    );
    port(
        clk         : in std_logic;
        we          : in std_logic;
        data_in     : in std_logic_vector(data_width-1 downto 0);
        data_out_r  : out std_logic_vector(data_width-1 downto 0);        
        address     : in std_logic_vector(addr_width-1 downto 0)
    );
end BlockRAM;

architecture rtl of BlockRAM is
    type ram_t is array(0 to (2**addr_width)-1) of std_logic_vector(data_in'range);
    signal RAM : ram_t;
begin

    proc_clk: process(clk)
        variable ram_index : integer;
    begin
        if rising_edge(clk) then
            ram_index := to_integer(unsigned(address));
            if we = '1' then
                RAM(ram_index) <= data_in;
                data_out_r <= data_in;
            else
                data_out_r <= RAM(ram_index);
            end if;
        end if; -- rising edge
    end process proc_clk;

end rtl;
