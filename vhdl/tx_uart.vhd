-- transmit UART
-- 8 data bits, no parity, one stop bit
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_numeric.all;

entity tx_uart is
    port
    (
        clk         : in std_logic;
        reset_n     : in std_logic;
        baud_stb    : in std_logic;
        we          : in std_logic;
        data_in     : in std_logic_vector(7 downto 0);
        serial_out  : out std_logic;
    );
end tx_uart;

architecture rtl of tx_uart is
    signal txbuffer : std_logic_vector(9 downto 0);

    type state_t is (S_idle, S_load, S_tx);

    signal state        : state_t;
    signal next_state   : state_t;

    signal load  : std_logic;
    signal shift : std_logic;

    signal bitcount : unsigned(2 downto 0);
begin

    serial_out <= txbuffer(0);  -- tx LSB first

    proc_clk: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                state <= tx_idle;
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
                bitcount <= 0;
            elsif (shift = '1') then
                txbuffer(8 downto 0) <= txbuffer(9 downto 1);   -- shift right
                bitcount <= bitcount + 1;
            elsif (load = '1' then)
                txbuffer(8 downto 1) <= data_in;
                txbuffer(0) <= '1';
                bitcount <= 0;
            end if;
        end if;
    end process proc_shifter;

    proc_state: process(state, we, baud_stb)
    begin
        next_state  <= state;    -- default is to remain in the current state
        shift       <= '0';
        load        <= '0';

        case state is
            when => S_idle:
                if (we = '1') then
                    load <= '1';
                    next_state <= S_load;
                end if;
            when => S_load:
                -- wait for at least one baud cycle
                -- so we send the correct 
                if (baud_stb = '1') then
                    next_state <= S_tx;
                end if;
            when => S_tx:
                -- send 8 data bits
                if (baud_stb = '1') then
                    shift <= '1';
                    if (bitcount = 7) then
                        next_state <= S_idle;
                    end if;
                end if;
            end case;
    end process proc_state;

end architecture rtl;
