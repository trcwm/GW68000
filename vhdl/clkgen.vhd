-- clock generator 100MHz -> 12.5 MHz
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clkgen is
    port
    (
        clk100M         : in std_logic;
        reset_n         : in std_logic;
        clk12M5         : out std_logic
    );
end clkgen;

architecture rtl of clkgen is
    signal clkdiv : unsigned(2 downto 0);
begin

    clk12M5 <= clkdiv(2);

    proc_clk: process(clk100M)
    begin
        if rising_edge(clk100M) then
            if (reset_n = '0') then
                clkdiv <= (others => '0');
            else
                clkdiv <= clkdiv + 1;
            end if;
        end if;
    end process proc_clk;

end architecture rtl;
