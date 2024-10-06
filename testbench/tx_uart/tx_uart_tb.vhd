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
    signal we      : std_logic := '0';


    signal bauddiv : unsigned(7 downto 0);
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
        we      <= '1'; -- strobe uart write
        wait for 2 us;
        we      <= '0'; -- strobe uart write
        
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

    -- generate a baud rate strobe
    proc_baud: process(clk, reset_n)
    begin
        if rising_edge(clk) then
            baudstb <= '0';    -- default value

            if (reset_n = '0') then
                bauddiv <= (others => '0');
            else
                bauddiv <= bauddiv + 1;
                if (bauddiv = baudmaxcount) then
                    bauddiv <= (others => '0');
                    baudstb <= '1';
                end if;
            end if;
        end if;
    end process proc_baud;
        
    u_dut: entity work.tx_uart(rtl)
        port map
        (
            clk         => clk,
            reset_n     => reset_n,
            baud_stb    => baudstb,
            data_in     => x"AA",
            we          => we
        );
    
end tb;
