-- receive UART using 4x oversampling
-- 8 data bits, no parity, one stop bit
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_uart is
    port
    (
        clk         : in std_logic;
        reset_n     : in std_logic;
        baud_stb    : in std_logic;     -- must be 4x the baud rate!
        read_stb    : in std_logic;     -- signal the data has been read
        data_out    : out std_logic_vector(7 downto 0);
        data_ready  : out std_logic;    -- ready to read rx data
        serial_in   : in std_logic
    );
end rx_uart;

architecture rtl of rx_uart is
    signal rxbuffer : std_logic_vector(9 downto 0);
    signal rxdata   : std_logic_vector(7 downto 0);

    type state_t is (S_idle, S_sync1, S_sync2, S_rx1, S_rx2, S_rx3, S_rx4, S_check, S_ready);

    signal state        : state_t;
    signal next_state   : state_t;

    signal shift : std_logic;
    signal latch : std_logic;
    signal clear : std_logic;

    signal bitcount : unsigned(3 downto 0);
    
    signal serial_in_d : std_logic;
    signal serial_edge_event : std_logic;
begin
    
    data_out   <= rxdata;
    data_ready <= '1' when state = S_ready else '0';

    -- detect falling edge of serial_in
    -- sampled at 4x the baud rate
    serial_edge_event <= (not serial_in) and serial_in_d;

    proc_clk: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                state <= S_idle;
                serial_in_d <= '1';
                rxdata <= (others => '0');
            else
                state <= next_state;
                if (baud_stb = '1') then
                    serial_in_d <= serial_in;
                end if;
                if (latch = '1') then
                    rxdata <= rxbuffer(8 downto 1);
                end if;
            end if;
        end if;
    end process proc_clk;

    -- receive shift register
    proc_shifter: process(clk, reset_n)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                rxbuffer <= (others => '1');
                bitcount <= (others => '0');
            elsif (shift = '1') then
                rxbuffer(9 downto 0) <= serial_in & rxbuffer(9 downto 1);   -- shift left
                bitcount <= bitcount + 1;
            elsif (clear = '1') then
                bitcount <= (others => '0');
            end if;
        end if;
    end process proc_shifter;

    proc_state: process(state, read_stb, baud_stb, bitcount, serial_edge_event, rxbuffer)
    begin
        -- defaults
        shift       <= '0';
        clear       <= '0';
        latch       <= '0';
        next_state  <= state;

        case state is
            when S_idle =>
                if (serial_edge_event = '1') and (baud_stb = '1') then
                    next_state <= S_sync1;
                end if;
            when S_sync1 =>
                -- delay by one baud_stb
                if (baud_stb = '1') then
                    clear <= '1';   -- clear the bitcount to zero
                    next_state <= S_sync2;
                end if;
            when S_sync2 =>
                -- delay by one baud_stb
                if (baud_stb = '1') then
                    next_state <= S_rx1;
                end if;
            when S_rx1 =>
                -- sample serial in
                if (baud_stb = '1') then
                    shift <= '1';
                    next_state <= S_rx2;
                end if;
            when S_rx2 =>
                if (baud_stb = '1') then
                    next_state <= S_rx3;
                end if;
            when S_rx3 =>
                if (baud_stb = '1') then
                    next_state <= S_rx4;
                end if;
            when S_rx4 =>
                if (baud_stb = '1') then
                    if (bitcount = 10) then
                        next_state <= S_check;
                    else 
                        next_state <= S_rx1;
                    end if;
                end if;
            when S_check =>
                -- check the start and stop bits
                if (rxbuffer(9) = '1' and rxbuffer(0) = '0') then
                    latch <= '1';
                    next_state <= S_ready;
                else                     
                    next_state <= S_idle;
                end if;
            when S_ready =>
                -- TODO: check start and stop bit
                if (read_stb = '1') then
                    next_state <= S_idle;
                end if;
            end case;
    end process proc_state;

end architecture rtl;
