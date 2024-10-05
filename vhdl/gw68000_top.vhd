-- Top level for the gw68000 system
-- Version          Description
--   0.1:           initial version
--   0.2:           changed TG68_fast to TG68, add spy program counter.

library ieee;
use ieee.std_logic_1164.all;

use work.TG68_fast;

entity gw68000_top is
    port
    (
        clk         : in std_logic;
        reset_n     : in std_logic
    );
end;

architecture rtl of gw68000_top is
    signal lds_n, uds_n  : std_logic;
    signal we_n     : std_logic;
    signal as       : std_logic;
    signal address  : std_logic_vector(31 downto 0);
    signal data_out : std_logic_vector(15 downto 0);
    signal data_in  : std_logic_vector(15 downto 0);

    signal ram_clk  : std_logic;
    signal cpu_clk  : std_logic;

    signal upper_we_n, lower_we_n : std_logic;

    signal spy_PC : std_logic_vector(31 downto 0);
begin 

    -- clock generator
    -- ram clock is clk
    -- cpu clock is clk/2 to hide block ram latency
    proc_clkgen: process(clk, reset_n)
    begin
        ram_clk <= clk;

        if rising_edge(clk) then
            if (reset_n = '0') then                
                cpu_clk <= '0';
            else
                cpu_clk <= not cpu_clk;
            end if;
        end if;
    end process proc_clkgen;

    upper_we_n <= we_n or uds_n;
    lower_we_n <= we_n or lds_n;

    u_ram_upper: entity work.BlockRAM(rtl)
        generic map
        (
            init_file  => "boot_upper.txt",
            data_width => 8,
            addr_width => 8
        )
        port map
        (
            clk         => clk,
            address     => address(8 downto 1),
            we_n        => upper_we_n,
            data_in     => data_out(15 downto 8),
            data_out_r  => data_in(15 downto 8)
        );

    u_ram_lower: entity work.BlockRAM(rtl)
        generic map
        (
            init_file  => "boot_lower.txt",
            data_width => 8,
            addr_width => 8
        )
        port map
        (
            clk         => clk,
            address     => address(8 downto 1),
            we_n        => lower_we_n,
            data_in     => data_out(7 downto 0),
            data_out_r  => data_in(7 downto 0)
        );

    u_cpu: entity work.TG68(logic)
        port map
        (
            clk         => cpu_clk,
            clkena_in   => '1',
            reset       => reset_n,
            dtack       => '0',
            data_in     => data_in,
            data_out    => data_out,
            addr        => address,
            as          => as,
            rw          => we_n,
            lds         => lds_n,
            uds         => uds_n,
            spy_PC      => spy_PC
        );

end rtl;
