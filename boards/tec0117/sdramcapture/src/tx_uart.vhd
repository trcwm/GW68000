-- transmit UART
-- 8 data bits, no parity, one stop bit
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_uart is
    port
    (
        clk         : in std_logic;
        reset_n     : in std_logic;
        baud_stb    : in std_logic;
        we_n        : in std_logic;
        data_in     : in std_logic_vector(7 downto 0);
        ready       : out std_logic;    -- ready to accept new tx data
        serial_out  : out std_logic
    );
end tx_uart;

architecture rtl of tx_uart is
    -- the tx buffer layout at load is as follows:
    -- 
    -- 1 d7 d6 d5 d4 d3 d2 d1 d0 0 1
    signal txbuffer : std_logic_vector(10 downto 0);

    type state_t is (S_idle, S_load, S_tx, S_stop);

    signal state        : state_t;
    signal next_state   : state_t;

    signal load  : std_logic;
    signal shift : std_logic;

    signal bitcount : unsigned(3 downto 0);
begin

    serial_out <= txbuffer(0);  -- tx LSB first

    --ready <= '1' when state = S_idle else '0';

    proc_clk: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                state <= S_idle;
            else
                state <= next_state;
            end if;
        end if;
    end process proc_clk;

    -- loadable shift register
    proc_shifter: process(clk, reset_n)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                txbuffer <= (others => '1');
                bitcount <= (others => '0');
            elsif (shift = '1') then
                txbuffer(9 downto 0) <= txbuffer(10 downto 1);   -- shift right
                bitcount <= bitcount + 1;
            elsif (load = '1') then
                txbuffer(9 downto 2) <= data_in;
                txbuffer(1) <= '0';
                txbuffer(0) <= '1';
                bitcount <= (others => '0');
            end if;
        end if;
    end process proc_shifter;

    proc_state: process(state, we_n, baud_stb, bitcount)
    begin
        ready       <= '0';
        shift       <= '0';
        load        <= '0';
        next_state  <= state;

        case state is
            when S_idle =>
                ready <= '1';
                if (we_n = '0') then
                    ready <= '0';
                    load  <= '1';
                    next_state <= S_tx;
                end if;
            when S_load =>
                -- wait for at least one baud cycle
                -- so we send the correct 
                if (baud_stb = '1') then
                    next_state <= S_tx;
                end if;
            when S_tx =>
                -- send start bit and 8 data bits                            
                if (baud_stb = '1') then
                    shift <= '1';
                    if (bitcount = 9) then
                        next_state <= S_stop;
                    end if;
                end if;
            when S_stop =>
                -- send the stop bit
                if (baud_stb = '1') then
                    shift <= '1';
                    next_state <= S_idle;
                end if;
            end case;
    end process proc_state;

end architecture rtl;
