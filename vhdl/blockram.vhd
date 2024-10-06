-- Configurable block RAM
-- Copyright Moseley Instruments (c) 2024
--
-- Block ram with configurable address and data widths
-- Supports initalization from a file
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE ieee.STD_LOGIC_TEXTIO.ALL;
use std.textio.all;

entity BlockRAM is
    generic
    (
        init_file  : string  := "blockram_bin.txt";
        data_width : integer := 16; -- data bus width in bits
        addr_width : integer := 8   -- address bus width in bits
    );
    port(
        clk         : in std_logic;
        we_n        : in std_logic;
        data_in     : in std_logic_vector(data_width-1 downto 0);
        data_out_r  : out std_logic_vector(data_width-1 downto 0);        
        address     : in std_logic_vector(addr_width-1 downto 0)
    );
end BlockRAM;

architecture behavioral of BlockRAM is
    constant num_entries : integer := 2**addr_width;
    type ram_t is array(0 to num_entries-1) of std_logic_vector(data_in'range);

    impure function init_ram return ram_t is
        file text_file       : text open read_mode is init_file;
        variable ok          : boolean;
        variable text_line   : line;
        variable ram_content : ram_t;
        variable index       : integer := 0;
    begin

        while not endfile(text_file) loop
            readline(text_file, text_line);

            if (text_line.all'length = 0) or (text_line.all(1) = '#') then
                next;
            end if;

            hread(text_line, ram_content(index));
            index := index + 1;

        end loop;

        return ram_content;
    end function;

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


architecture rtl of BlockRAM is
    constant num_entries : integer := 2**addr_width;
    type ram_t is array(0 to num_entries-1) of std_logic_vector(data_in'range);
    signal RAM : ram_t;
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

end rtl;
