-- Top level for the gw68000 system
-- Version          Description
--   0.1:           initial version

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gw68000_top;

entity tec0117_top is
    port
    (
        clk12M          : in std_logic;
        userbutton      : in std_logic;
        leds            : out std_logic_vector(7 downto 0);
        serial_out      : out std_logic;
        serial_in       : in std_logic;
        serial_cts_n    : in std_logic
    );
end;

architecture rtl of tec0117_top is
    signal spy_PC  : std_logic_vector(31 downto 0);
begin

    u_gw68000: entity gw68000_top(rtl)
        generic map
        (
            g_upper_ram     => "/storage/programming/gw68000/ghdl/boot_upper.txt",
            g_lower_ram     => "/storage/programming/gw68000/ghdl/boot_lower.txt"
        )
        port map
        (
            clk             => clk12M,
            reset_n         => userbutton,
            leds            => leds,
            serial_out      => serial_out,
            serial_in       => serial_in,
            serial_cts_n    => serial_cts_n,
            spy_PC          => spy_PC
        );

end rtl;
