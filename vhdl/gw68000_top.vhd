-- Top level for the gw68000 system

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
    signal lds,uds  : std_logic;
    signal wr       : std_logic;
    signal address  : std_logic_vector(31 downto 0);
    signal data_out : std_logic_vector(15 downto 0);
begin 
    u_cpu: entity work.TG68_fast(logic)
        port map
        (
            clk         => clk,
            reset       => reset_n,
            data_in     => (others => '0'),
            data_write  => data_out,
            address     => address,
            wr          => wr,
            LDS         => lds,
            UDS         => uds
        );

end rtl;
