-- Testbench for tx_uart
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_uart_tb is
end entity;

architecture tb of rx_uart_tb is
    signal do_sim  : std_logic := '1';
    signal clk     : std_logic := '0';
    signal reset_n : std_logic := '1';
    signal we_n    : std_logic := '1';

    signal baudstb      : std_logic;
    signal serial_data  : std_logic;

    -- should be 0x55
    constant serial_stim : string := "----____----____----____----____----____--------";
    signal   serial_idx  : integer := 1;
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

    -- generate a 12 MHz clock for simulation
    proc_clk: process
    begin
        if (do_sim = '1') then
            wait for 41.6 ns;
            clk <= not clk;
        else
            wait;
        end if;
    end process proc_clk;

    u_baudgen: entity work.baudgen(rtl)
        generic map
        (
            g_clkrate  => 12000000,
            g_baudrate => 4000000   -- 4x the actual baud rate!
        )
        port map
        (
            clk             => clk,
            reset_n         => reset_n,
            baud_stb_out    => baudstb
        );

    proc_serial: process(clk, baudstb, reset_n)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                serial_data <= '1';
            elsif (baudstb='1') then
                if (serial_stim(serial_idx) = '-') then
                    serial_data <= '1';
                else
                    serial_data <= '0';
                end if;            

                if (serial_idx = (serial_stim'length-1)) then
                    serial_idx <= 1;

                else
                    serial_idx <= serial_idx + 1;
                end if;
            end if;
        end if;
    end process proc_serial;

    u_dut: entity work.rx_uart(rtl)
        port map
        (
            clk         => clk,
            reset_n     => reset_n,
            baud_stb    => baudstb,
            data_out    => open,
            read_stb    => '1',
            serial_in   => serial_data
        );
    
end tb;
