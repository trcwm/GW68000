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
        clk100M         : in std_logic;
        userbutton      : in std_logic;
        leds            : out std_logic_vector(7 downto 0);

        serial_out      : out std_logic;
        serial_in       : in std_logic;
        serial_cts_n    : in std_logic;

        -- sdram IO
        O_sdram_clk     : out std_logic;
        O_sdram_cke     : out std_logic;
        O_sdram_cas_n   : out std_logic;
        O_sdram_ras_n   : out std_logic;
        O_sdram_wen_n   : out std_logic;
        O_sdram_dqm     : out std_logic_vector(1 downto 0);
        O_sdram_ba      : out std_logic_vector(1 downto 0);
        IO_sdram_dq     : inout std_logic_vector(15 downto 0);
        O_sdram_addr    : out std_logic_vector(11 downto 0)
    );
end;

architecture rtl of tec0117_top is
    signal clk12M5 : std_logic;
    signal spy_PC  : std_logic_vector(31 downto 0);
begin

    u_clkgen: entity work.clkgen(rtl)
        port map
        (
            clk100M => clk100M,
            reset_n => userbutton,
            clk12M5 => clk12M5
        );

    u_gw68000: entity gw68000_top(rtl)
        generic map
        (
            g_upper_ram     => "/storage/programming/gw68000/ghdl/boot_upper.txt",
            g_lower_ram     => "/storage/programming/gw68000/ghdl/boot_lower.txt"
        )
        port map
        (
            clk100M         => clk100M,
            clk12M5         => clk12M5,
            reset_n         => userbutton,
            leds            => leds,
            serial_out      => serial_out,
            serial_in       => serial_in,
            serial_cts_n    => serial_cts_n,
            spy_PC          => spy_PC,

            O_sdram_clk     => O_sdram_clk,
            O_sdram_cke     => O_sdram_cke,
            O_sdram_cas_n   => O_sdram_cas_n,
            O_sdram_ras_n   => O_sdram_ras_n,
            O_sdram_wen_n   => O_sdram_wen_n,
            O_sdram_dqm     => O_sdram_dqm,
            O_sdram_ba      => O_sdram_ba,
            IO_sdram_dq     => IO_sdram_dq,
            O_sdram_addr    => O_sdram_addr
        );

end rtl;
