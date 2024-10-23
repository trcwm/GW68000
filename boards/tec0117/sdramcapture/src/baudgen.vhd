-- baud strobe generator for UARTS
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baudgen is
    generic
    (
        g_clkrate  : integer := 12000000;
        g_baudrate : integer := 9600
    );
    port
    (
        clk             : in std_logic;
        reset_n         : in std_logic;
        baud_stb_out    : out std_logic
    );
end baudgen;

architecture rtl of baudgen is
    signal bauddiv : unsigned(11 downto 0);

    function calcBaudMax(ClockRate : integer := 0;
                         BaudRate  : integer := 0) return unsigned is
    begin
        return to_unsigned((ClockRate / BaudRate)-1, bauddiv'length);
    end function;

    signal baudmax : unsigned(11 downto 0) := calcBaudMax(g_clkrate, g_baudrate);
begin

    proc_clk: process(clk)
    begin
        if rising_edge(clk) then
            baud_stb_out <= '0';    -- default

            if (reset_n = '0') then
                bauddiv <= baudmax;
            else 
                bauddiv <= bauddiv-1;
                if (bauddiv = x"000") then
                    bauddiv <= baudmax;
                    baud_stb_out <= '1';
                end if;
            end if;
        end if;
    end process proc_clk;

end architecture rtl;
