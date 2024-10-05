-- Top level for the gw68000 system

library ieee;
use ieee.std_logic_1164.all;

use work.TG68_fast;

entity gw68000_top is
    port
    (
        clk         : in std_logic;
        reset       : in std_logic
    );
end;

architecture rtl of gw68000_top is
begin 
    u_cpu: entity work.TG68_fast(logic)
        port map
        (
            clk     => clk,
            reset   => reset,
            data_in => (others => '0')
        );

end rtl;
