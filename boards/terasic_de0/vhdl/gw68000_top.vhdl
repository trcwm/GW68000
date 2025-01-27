-- Top level for the gw68000 system
-- Version          Description
--   0.1:           initial version

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gw68000_top;
use work.seg7;

entity terasic_de0_top is
    port
    (
        clk50MHz    : in std_logic;
        reset_n     : in std_logic;
        leds        : out std_logic_vector(9 downto 0);
        digit0      : out std_logic_vector(7 downto 0);
        digit1      : out std_logic_vector(7 downto 0);
        digit2      : out std_logic_vector(7 downto 0);
        digit3      : out std_logic_vector(7 downto 0);
        uart_rxd    : in std_logic;
        uart_txd    : out std_logic
    );
end entity;

architecture rtl of terasic_de0_top is
    signal clk12M5 : std_logic;
    signal clkdiv  : unsigned(19 downto 0) := (others => '0');
    signal spy_PC  : std_logic_vector(31 downto 0);
begin

    proc_clk: process(clk50MHz)
    begin
        if rising_edge(clk50MHz) then
            if (reset_n = '0') then
                clkdiv <= (others => '0');
            else
                clkdiv <= clkdiv + 1;
            end if;
        end if;
    end process proc_clk;

    clk12M5 <= clkdiv(1);

    u_gw68000: entity gw68000_top(rtl)
        port map
        (
            clk12M5         => clk12M5,
            reset_n         => reset_n,
            leds            => leds(7 downto 0),
            serial_out      => uart_txd,
            serial_in       => uart_rxd,
            serial_cts_n    => '0',
            spy_PC          => spy_PC
        );

    leds(8) <= '0';
    leds(9) <= '0';

    u_digit0: entity seg7(rtl)
        port map
        (
            digit_in => spy_PC(3 downto 0),
            segs_out => digit0,
            dot_in   => '0'
        );

    u_digit1: entity seg7(rtl)
        port map
        (
            digit_in => spy_PC(7 downto 4),
            segs_out => digit1,
            dot_in   => '0'
        );

    u_digit2: entity seg7(rtl)
        port map
        (
            digit_in => spy_PC(11 downto 8),
            segs_out => digit2,
            dot_in   => '0'
        );

    u_digit3: entity seg7(rtl)
        port map
        (
            digit_in => spy_PC(15 downto 12),
            segs_out => digit3,
            dot_in   => '0'
        );

end rtl;
