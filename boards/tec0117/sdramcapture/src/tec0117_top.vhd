-- Top level SDRAM capture
-- Version          Description
--   0.1:           initial version, GOWIN IP works
--   0.2;           capture RAS, CAS, WR and ADDR to the SDRAM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.SDRAM_controller;

entity tec0117_top is
    port
    (
        clk12M          : in std_logic;
        userbutton      : in std_logic;
        leds            : out std_logic_vector(7 downto 0);

        serial_out      : out std_logic;
        serial_in       : in std_logic;
        serial_cts_n    : in std_logic;

        -- sdram IO
        O_sdram_clk     : out std_logic;
        O_sdram_cs_n    : out std_logic;
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

    signal sdram_in_data    : std_logic_vector(15 downto 0);
    signal sdram_out_data   : std_logic_vector(15 downto 0);
    signal sdram_init_done  : std_logic;
    signal sdram_busy_n     : std_logic;
    signal sdram_rd_valid   : std_logic;
    signal sdram_wrd_ack    : std_logic;
    signal sdram_dq_drive   : std_logic;

    signal reset_n  : std_logic := '1';

    -- faked clock signal used to drive the SDRAM IP
    -- generated by the state machine
    signal ip_clk   : std_logic;  

    type state_t is (S_start, S_sync1, S_sync2, S_cnt, S_byte1, S_byte2, S_byte3, S_byte4, S_clk, S_done);
    signal state : state_t := S_start;

    type state2_t is (S2_start, S2_dowrite, S2_write_waitack, S2_write_wait, S2_waitdone, S2_doread, S2_waitrdvalid, S2_waitready, S2_done);
    signal state2 : state2_t := S2_start;

    signal baud_stb     : std_logic;
    signal uart_we_n    : std_logic;
    signal uart_data_in : std_logic_vector(7 downto 0);
    signal uart_ready   : std_logic;

    signal wr_n : std_logic := '1';
    signal rd_n : std_logic := '1';

    signal counter : unsigned(7 downto 0);
    signal byte1 : std_logic_vector(7 downto 0);
    signal byte2 : std_logic_vector(7 downto 0);
    signal byte3 : std_logic_vector(7 downto 0);
    signal byte4 : std_logic_vector(7 downto 0);

    signal terminate : std_logic := '0';

begin

    reset_n <= userbutton;

    byte1 <= sdram_init_done & 
        O_sdram_dqm    &
        sdram_dq_drive &
        O_sdram_cs_n   &
        O_sdram_ras_n  &
        O_sdram_cas_n  &
        O_sdram_wen_n;

    byte2 <= O_sdram_addr(7 downto 0);
    byte3 <= O_sdram_ba & "00" & O_sdram_addr(11  downto 8);
    byte4 <= "000" & wr_n & rd_n & sdram_busy_n & sdram_rd_valid & sdram_wrd_ack;

    sdram_in_data <= x"AA55";

    u_baudgen: entity work.baudgen(rtl)
        generic map
        (
            g_clkrate   => 12000000,
            g_baudrate  => 115200
        )
        port map
        (
            clk          => clk12M,
            reset_n      => reset_n,
            baud_stb_out => baud_stb
        );

    u_txuart: entity work.tx_uart(rtl)
        port map
        (
            clk         => clk12M,
            reset_n     => reset_n,
            baud_stb    => baud_stb,
            we_n        => uart_we_n,
            data_in     => uart_data_in,
            ready       => uart_ready,
            serial_out  => serial_out
        );

    u_sdram: entity work.SDRAM_controller(beh)
        port map
        (
            O_sdram_clk     => O_sdram_clk,
            O_sdram_cke     => O_sdram_cke,
            O_sdram_cs_n    => O_sdram_cs_n,
            O_sdram_cas_n   => O_sdram_cas_n,
            O_sdram_ras_n   => O_sdram_ras_n,
            O_sdram_wen_n   => O_sdram_wen_n,
            O_sdram_dqm     => O_sdram_dqm,
            O_sdram_addr    => O_sdram_addr,
            O_sdram_ba      => O_sdram_ba,
            IO_sdram_dq     => IO_sdram_dq,
            I_sdrc_rst_n    => userbutton,
            I_sdrc_clk      => ip_clk,
            I_sdram_clk     => not ip_clk,
            I_sdrc_selfrefresh => '0',
            I_sdrc_power_down  => '0',
            I_sdrc_wr_n     => wr_n,
            I_sdrc_rd_n     => rd_n,
            I_sdrc_addr     => (others => '0'),
            I_sdrc_data_len => (others => '0'),     -- one word
            I_sdrc_dqm      => "00",
            I_sdrc_data     => sdram_in_data,
            O_sdrc_data     => sdram_out_data,
            O_sdrc_init_done => sdram_init_done,
            O_sdrc_busy_n   => sdram_busy_n,
            O_sdrc_rd_valid => sdram_rd_valid,
            O_sdrc_wrd_ack  => sdram_wrd_ack,

            O_dq_drive      => sdram_dq_drive
        );

    proc_ctrlfsm: process(clk12M)
    begin
        if rising_edge(clk12M) then
            -- defaults
            uart_we_n <= '1';
            ip_clk    <= '0';
            --leds <= (others => '0');

            if (reset_n = '0') then
                counter <= (others => '0');
                state   <= S_start;
            else
                case state is
                    when S_start =>
                        state <= S_sync1;
                    when S_sync1 =>
                        if (uart_ready = '1') then
                            state        <= S_sync2;
                            uart_we_n    <= '0';
                            uart_data_in <= x"AA";
                        end if;
                    when S_sync2 =>
                        if (uart_ready = '1') then
                            state        <= S_cnt;
                            uart_we_n    <= '0';
                            uart_data_in <= x"55";
                        end if;
                    when S_cnt =>
                        if (uart_ready = '1') then
                            state        <= S_byte1;
                            uart_we_n    <= '0';
                            uart_data_in <= std_logic_vector(counter);
                            counter <= counter+1;
                        end if;                        
                    when S_byte1 =>
                        if (uart_ready = '1') then
                            state        <= S_byte2;
                            uart_we_n    <= '0';
                            uart_data_in <= byte1;
                        end if;
                    when S_byte2 =>
                        if (uart_ready = '1') then
                            state        <= S_byte3;
                            uart_we_n    <= '0';
                            uart_data_in <= byte2;
                        end if;
                    when S_byte3 =>
                        if (uart_ready = '1') then
                            state        <= S_byte4;
                            uart_we_n    <= '0';
                            uart_data_in <= byte3;
                        end if;
                    when S_byte4 =>
                        if (uart_ready = '1') then
                            state        <= S_clk;
                            uart_we_n    <= '0';
                            uart_data_in <= byte4;
                        end if;                        
                    when S_clk =>
                        ip_clk <= '1';                        
                        state <= S_sync1;
                    when S_done =>
                        null;
                end case;

                if (terminate = '1') then
                    state <= S_done;
                end if;
            end if;
        end if;
    end process proc_ctrlfsm;

    proc_doread: process(clk12M)
    begin        
        if rising_edge(clk12M) then
            
            if (reset_n = '0') then
                terminate <= '0';
                state2    <= S2_start;
            else
                if (ip_clk = '1') then
                    -- defaults
                    rd_n <= '1';
                    wr_n <= '1';
                    leds <= (others => '0');

                    case state2 is
                        when S2_start =>
                            if (sdram_init_done = '1') then
                                state2 <= S2_dowrite;
                            end if;
                        when S2_dowrite =>
                            wr_n <= '0';
                            state2 <= S2_write_waitack;
                        when S2_write_waitack =>
                            if (sdram_wrd_ack = '1') then
                                state2 <= S2_write_wait;
                            end if;
                        when S2_write_wait =>
                            if (sdram_busy_n = '1') then
                                state2 <= S2_doread;
                            end if;
                        when S2_doread  =>
                            leds <= "00000010";
                            rd_n <= '0';
                            state2 <= S2_waitrdvalid;
                        when S2_waitrdvalid =>
                            leds <= "00000100";
                            if (sdram_rd_valid = '1') then
                                state2 <= S2_waitready;
                            end if;
                        when S2_waitready =>
                            leds <= "00001000";
                            if (sdram_busy_n = '1') then
                                state2 <= S2_done;
                            end if;
                        when S2_done =>
                            leds <= (others => '1');
                            terminate <= '1';
                    end case;
                end if; -- ip clk
            end if; --reset
        end if; -- rising edge
    end process proc_doread;

end rtl;