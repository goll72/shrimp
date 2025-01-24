library ieee;

use ieee.std_logic_1164.all;

use work.attrs.all;

entity cpu is 
    port (
        clk, rst : in std_logic;
        d_in : in word_t;
        d_out : out word_t
    );
end entity;

architecture structural of cpu is 

begin

end architecture;
