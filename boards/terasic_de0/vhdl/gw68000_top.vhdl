-- Top level for the gw68000 system
-- Version          Description
--   0.1:           initial version

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gw68000_top;

entity terasic_de0_top is
    port
    (
        clk50MHz    : in std_logic;
        reset_n     : in std_logic;
        leds        : out std_logic_vector(9 downto 0);
        uart_rxd    : in std_logic;
        uart_txd    : out std_logic
    );
end entity;



architecture rtl of terasic_de0_top is
    signal clkdiv  : unsigned(1 downto 0) := (others => '0');
    signal clk12M5 : std_logic;
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

    clk12M5 <= clkdiv(0);

    u_gw68000: entity gw68000_top(rtl)
        generic map
        (
            g_upper_ram     => "/gw68000/ghdl/boot_upper.txt",
            g_lower_ram     => "/gw68000/ghdl/boot_lower.txt"
        )
        port map
        (
            clk100M         => clk12M5,
            clk12M5         => clk12M5,
            reset_n         => '1',
            leds            => open,
            serial_out      => uart_txd,
            serial_in       => uart_rxd,
            serial_cts_n    => '0',
            spy_PC          => spy_PC
        );

    leds(9 downto 0) <= spy_PC(9 downto 0);

end rtl;
