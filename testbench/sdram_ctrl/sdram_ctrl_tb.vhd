-- Testbench for SDRAM controller
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_ctrl_tb is
end entity;

architecture tb of sdram_ctrl_tb is
    signal do_sim  : std_logic := '1';
    signal clk     : std_logic := '0';
    signal reset_n : std_logic := '1';
    signal we_n    : std_logic := '1';

begin

    -- simulation control process
    proc_sim: process
    begin
        wait for 2 us;
        reset_n <= '0';
        wait for 8 us;
        reset_n <= '1';
        we_n    <= '0'; -- strobe uart write
        wait for 2 us;
        we_n    <= '1'; -- strobe uart write
        
        wait for 400 us;
        do_sim <= '0';  -- end simulation
        wait;
    end process proc_sim;

    -- generate a 100 MHz clock for simulation
    proc_clk: process
    begin
        if (do_sim = '1') then
            wait for 5 ns;
            clk <= not clk;
        else
            wait;
        end if;
    end process proc_clk;

    u_dut: entity work.sdram_ctrl(rtl)
        port map
        (
            clk         => clk,
            reset_n     => reset_n,

            sdram_dq    => open,

            lds_n       => '1',
            uds_n       => '1',
            data_in     => (others => '0'),
            data_out    => open,
            addr        => (others => '0'),
            we_n        => '1',
            wr_stb      => '0',
            refresh_stb => '0'
        );
    
end tb;
