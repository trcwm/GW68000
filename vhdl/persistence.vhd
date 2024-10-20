-- persistence control for LEDs
-- to easily see whether a signal is on
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity persistence is
    generic
    (
        counterbits : integer := 23    -- ~10Hz at 100MHz clock
    );
    port
    (
        clk     : in std_logic;
        reset_n : in std_logic;
        sig_in  : in std_logic;
        sig_out : out std_logic
    );
end persistence;

architecture rtl of persistence is
    signal sig_prev         : std_logic;
    signal sig_out_local    : std_logic;
    signal counter  : unsigned(counterbits-1 downto 0);
begin

    sig_out <= sig_out_local;

    proc_clk: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                sig_prev <= '0';
                sig_out_local <= '0';
                counter <= to_unsigned(0, counter'LENGTH);
            else
                -- check for rising edge of sig
                if ((sig_prev = '0') and (sig_in = '1')) then
                    counter <= (others => '0');
                    sig_out_local <= '1';
                else
                    counter <= counter + 1;
                    if (counter(counterbits-1) = '1') then
                        sig_out_local <= '0';
                        counter <= (others => '0');
                    end if;
                end if;
                sig_prev <= sig_in;
            end if;
        end if;
    end process proc_clk;

end architecture rtl;
