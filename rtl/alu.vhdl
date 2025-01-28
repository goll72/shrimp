library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.attrs.all;
use work.opcode.all;

entity alu is
    port (
        op : in opcode_t;
        in_1, in_2 : in word_t;
        sgn, rot : in std_logic;
        d_out : out word_t
    );
end entity;

architecture rtl of alu is
    alias shift_amount is in_2(SHIFT_AMOUNT_BITS - 1 downto 0);

    -- Shift fill value, will be '0' on logical shifts and
    -- will correspond to the sign bit on arithmetic shifts
    signal shift_fill : std_logic;
    signal barrel_in, barrel_out : word_t;
begin
    shifter : entity work.barrel_shifter port map (
        d_in => in_1,
        amount => shift_amount,
        rot => rot,
        fill => shift_fill,
        d_out => barrel_out
    );

    do_op : process(all) is
    begin
        barrel_in <= in_1;
        shift_fill <= '0';
        
        case op is
            when OP_SHL =>
                d_out <= barrel_out;
            when OP_SHR | OP_SHA =>
                -- Reverse the input bits, shift and then reverse the output 
                -- bits, effectively shifting in the other direction
                for i in WORD_BITS - 1 downto 0 loop
                    barrel_in(WORD_BITS - 1 - i) <= in_1(i);
                    d_out(WORD_BITS - 1 - i) <= barrel_out(i);
                end loop;

                if op = OP_SHA then
                    shift_fill <= in_1(in_1'high);
                end if;
            -- XXX
            when others =>
        end case;
    end process;
end architecture;
