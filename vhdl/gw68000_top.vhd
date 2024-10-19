-- Top level for the gw68000 system
-- Version          Description
--   0.1:           initial version
--   0.2:           changed TG68_fast to TG68, add spy program counter.
--   0.3:           added tx uart

library ieee;
use ieee.std_logic_1164.all;

use work.TG68_fast;

entity gw68000_top is
    generic
    (
        g_upper_ram       : string := "boot_upper.txt";
        g_lower_ram       : string := "boot_lower.txt"
    );
    port
    (
        clk100M         : in std_logic;
        clk12M5         : in std_logic;
        reset_n         : in std_logic;
        leds            : out std_logic_vector(7 downto 0);
        serial_out      : out std_logic;
        serial_in       : in std_logic;
        serial_cts_n    : in std_logic;
        spy_PC          : out std_logic_vector(31 downto 0);

        O_sdram_clk     : out std_logic;
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

architecture rtl of gw68000_top is
    signal lds_n, uds_n  : std_logic;
    signal we_n     : std_logic;
    signal as_n     : std_logic;
    signal address  : std_logic_vector(31 downto 0);
    signal data_out : std_logic_vector(15 downto 0);
    signal data_in  : std_logic_vector(15 downto 0);

    signal ram_data_out     : std_logic_vector(15 downto 0);
    signal sdram_data_out   : std_logic_vector(15 downto 0);
    signal sdram_we_n       : std_logic;
    signal sdram_rw         : std_logic;
    signal uart_status      : std_logic_vector(7 downto 0);
    
    signal uart_rxdata  : std_logic_vector(7 downto 0);

    signal upper_we_n, lower_we_n, tx_uart_we_n : std_logic;
    signal rx_baud_stb, tx_baud_stb : std_logic;
    signal rx_uart_full, tx_uart_empty : std_logic;
    signal rx_uart_read_stb : std_logic;

    signal spy_PC_local : std_logic_vector(31 downto 0);
begin 

    O_sdram_clk <= clk100M;

    -- address decoding:

    -- preliminary:
    -- 0x01000000 is the start of the IO space
    tx_uart_we_n <= as_n when (address(31 downto 24) = x"01" and we_n = '0') else '1';

    -- RAM decoding
    upper_we_n <= as_n when (address(31 downto 24) = x"00" and we_n = '0' and uds_n = '0') else '1';
    lower_we_n <= as_n when (address(31 downto 24) = x"00" and we_n = '0' and lds_n = '0') else '1';

    -- SDRAM decoding
    sdram_rw   <= '1' when (address(31 downto 24) = x"10" and as_n = '0') else '0';
    sdram_we_n <= we_n when (sdram_rw = '1') else '1';

    -- 68000 data_in generation
    proc_addr_decoder: process(
        address, 
        as_n, 
        we_n, 
        uart_status, 
        uart_rxdata, 
        ram_data_out,
        sdram_data_out)
    begin
        rx_uart_read_stb <= '0';
        data_in <= (others => '0');
        
        if (we_n = '1' and as_n = '0') then
            case (address(31 downto 24)) is
                when x"00" =>
                    -- block ram for booting
                    data_in <= ram_data_out;
                when x"01" =>
                    -- IO space
                    if (address(2) = '0') then
                        data_in <= x"00" & uart_status;
                    else
                        rx_uart_read_stb <= '1';
                        data_in <= x"00" & uart_rxdata;
                    end if;
                when others =>
                    -- SDRAM
                    data_in <= sdram_data_out;
            end case;
        end if;

    end process proc_addr_decoder;

    leds <= uart_status;

    --leds(7 downto 1) <= spy_PC_local(7 downto 1);
    --leds(0)          <= not serial_cts_n;

    spy_PC <= spy_PC_local;

    -- ================================================================
    --   BLOCK RAM
    -- ================================================================

    u_ram_upper: entity work.BlockRAM(behavioral)
        generic map
        (
            init_file  => g_upper_ram,
            data_width => 8,
            addr_width => 8
        )
        port map
        (
            clk         => clk12M5,
            address     => address(8 downto 1),
            we_n        => upper_we_n,
            data_in     => data_out(15 downto 8),
            data_out_r  => ram_data_out(15 downto 8)
        );

    u_ram_lower: entity work.BlockRAM(behavioral)
        generic map
        (
            init_file  => g_lower_ram,
            data_width => 8,
            addr_width => 8
        )
        port map
        (
            clk         => clk12M5,
            address     => address(8 downto 1),
            we_n        => lower_we_n,
            data_in     => data_out(7 downto 0),
            data_out_r  => ram_data_out(7 downto 0)
        );

    -- ================================================================
    --   68k core
    -- ================================================================

    u_cpu: entity work.TG68(logic)
        port map
        (
            clk         => clk12M5,
            clkena_in   => '1',
            reset       => reset_n,
            dtack       => '0',
            data_in     => data_in,
            data_out    => data_out,
            addr        => address,
            as          => as_n,
            rw          => we_n,
            lds         => lds_n,
            uds         => uds_n,
            spy_PC      => spy_PC_local
        );

    -- ================================================================
    --   SDRAM RAM
    -- ================================================================

    u_sdram_ctrl: entity work.sdram_ctrl(rtl)
        port map
        (
            clk         => clk100M,
            reset_n     => reset_n,
            refresh_i   => '0',
            rw_i        => sdram_rw,
            we_n        => sdram_we_n,
            addr_i      => address(22 downto 1),
            data_i      => data_out,
            uds_n       => uds_n,
            lds_n       => lds_n,
            ready_o     => open,
            done_o      => open,
            data_o      => sdram_data_out,
      
            -- SDRAM side
            sdram_cke   => O_sdram_cke,
            sdram_cs_n  => open,
            sdram_ras_n => O_sdram_ras_n,
            sdram_cas_n => O_sdram_cas_n,
            sdram_wen_n => O_sdram_wen_n,
            sdram_ba    => O_sdram_ba,
            sdram_addr  => O_sdram_addr,
            sdram_dq    => IO_sdram_dq,
            sdram_dqm   => O_sdram_dqm
        );

    -- ================================================================
    --   IO peripherals
    -- ================================================================

    u_txbaudgen: entity work.baudgen(rtl)
        generic map
        (
            g_clkrate   => 12500000,
            g_baudrate  => 115200            
        )
        port map
        (
            clk          => clk12M5,
            reset_n      => reset_n,
            baud_stb_out => tx_baud_stb
        );

    u_tx_uart: entity work.tx_uart(rtl)
        port map
        (
            clk         => clk12M5,
            reset_n     => reset_n,
            we_n        => tx_uart_we_n,
            data_in     => data_out(7 downto 0),
            baud_stb    => tx_baud_stb,
            serial_out  => serial_out,
            ready       => tx_uart_empty
        );

    u_rxbaudgen: entity work.baudgen(rtl)
        generic map
        (
            g_clkrate   => 12500000,
            g_baudrate  => 115200*4     -- rx requires 4x the rate
        )
        port map
        (
            clk          => clk12M5,
            reset_n      => reset_n,
            baud_stb_out => rx_baud_stb
        );

    u_rx_uart: entity work.rx_uart(rtl)
        port map
        (
            clk         => clk12M5,
            reset_n     => reset_n,
            baud_stb    => rx_baud_stb,
            serial_in   => serial_in,
            read_stb    => rx_uart_read_stb,
            data_out    => uart_rxdata,
            data_ready  => rx_uart_full
        );

    -- generate uart status register
    uart_status <= "000000" & rx_uart_full & tx_uart_empty;

end rtl;
