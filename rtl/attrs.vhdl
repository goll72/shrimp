library ieee;

use ieee.std_logic_1164.all;

package attrs is
    constant WORD_BITS : natural := 16;
    
    subtype word_t is std_logic_vector(WORD_BITS - 1 downto 0);
    subtype reg_addr_t is std_logic_vector(4 downto 0);
    subtype opcode_t is std_logic_vector(4 downto 0);
end package;
