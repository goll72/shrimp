library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.attrs.all;

entity memory is
    port (
        clk : in std_logic;
        en, r, w : in std_logic;
        addr : in word_t;
        d_in : in word_t;
        d_out : out word_t
    );
end entity;

architecture behavioral of memory is
    type mem_array_t is array(0 to 2 ** WORD_BITS - 1) of word_t;

    signal data : mem_array_t;
begin
    process(clk, addr) is
        variable addr_index : integer := to_integer(unsigned(addr));
    begin
        if rising_edge(clk) then
            if en = '1' and r = '1' then
                d_out <= data(addr_index);
            else
                d_out <= (others => 'Z');
            end if;

            if en = '1' and w = '1' then
                data(addr_index) <= d_in;
            end if;
        end if;
    end process;
end architecture;
