-- Testbench for gw68000_top 
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;

entity gw68000_tb is
end entity;

architecture tb of gw68000_tb is
    signal do_sim : std_logic := '1';
    signal clk    : std_logic := '0';
    signal reset  : std_logic := '0';
begin

    proc_sim: process
    begin
        wait for 2 us;
        reset <= '1';
        wait for 2 us;
        reset <= '0';

        wait for 100 us;
        do_sim <= '0';  -- end simulation
        wait;
    end process proc_sim;

    -- generate a 1 MHz clock for simulation
    proc_clk: process
    begin
        if (do_sim = '1') then
            wait for 500 ns;
            clk <= not clk;
        else
            wait;
        end if;
    end process proc_clk;


end tb;
