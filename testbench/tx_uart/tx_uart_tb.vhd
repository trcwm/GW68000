-- Testbench for tx_uart
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_uart_tb is
end entity;

architecture tb of tx_uart_tb is
    signal do_sim  : std_logic := '1';
    signal clk     : std_logic := '0';
    signal reset_n : std_logic := '1';
    signal we_n    : std_logic := '1';

    signal baudstb : std_logic;

    constant baudmaxcount : unsigned(7 downto 0) := to_unsigned(16, 8);
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

    u_baudgen: entity work.baudgen(rtl)
        generic map
        (
            g_baudrate => 1000000
        )
        port map
        (
            clk             => clk,
            reset_n         => reset_n,
            baud_stb_out    => baudstb
        );

    u_dut: entity work.tx_uart(rtl)
        port map
        (
            clk         => clk,
            reset_n     => reset_n,
            baud_stb    => baudstb,
            data_in     => x"AA",
            we_n        => we_n
        );
    
end tb;
