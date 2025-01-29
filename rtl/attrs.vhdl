library ieee;

use ieee.std_logic_1164.all;
use ieee.math_real.log2;

package attrs is
    constant WORD_BITS : natural := 16;
    constant BYTE_BITS : natural := 8;
    constant SHIFT_AMOUNT_BITS : natural := 4;
    
    subtype word_t is std_logic_vector(WORD_BITS - 1 downto 0);
    subtype reg_addr_t is std_logic_vector(4 downto 0);
    subtype opcode_t is std_logic_vector(4 downto 0);
end package;
