-- Testbench for gw68000_top 
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;

entity gw68000_tb is
end entity;

architecture tb of gw68000_tb is
    signal do_sim  : std_logic := '1';
    signal clk100M : std_logic := '0';
    signal clk12M5 : std_logic := '0';
    signal reset_n : std_logic := '1';
begin

    -- simulation control process
    proc_sim: process
    begin
        wait for 2 us;
        reset_n <= '0';
        wait for 200 us;
        reset_n <= '1';

        wait for 100 us;
        do_sim <= '0';  -- end simulation
        wait;
    end process proc_sim;

    -- generate a 100 MHz clock for simulation
    proc_clk100M: process
    begin
        if (do_sim = '1') then
            wait for 5 ns;
            clk100M <= not clk100M;
        else
            wait;
        end if;
    end process proc_clk100M;

    u_clkgen: entity work.clkgen(rtl)
        port map
        (
            clk100M => clk100M,
            reset_n => reset_n,
            clk12M5 => clk12M5
        );

    u_dut: entity work.gw68000_top(rtl)
        generic map
        (
            g_upper_ram => "boot_upper.txt",
            g_lower_ram => "boot_lower.txt"
        )
        port map
        (
            clk100M         => clk100M,
            clk12M5         => clk12M5,
            reset_n         => reset_n,
            serial_in       => '0',
            serial_cts_n    => '1'
        );
    
end tb;
