library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.attrs.all;
use work.opcode.all;

entity alu is
    port (
        op : in opcode_t;
        in_1, in_2 : in word_t;
        sgn, rot, wrd : in std_logic;
        d_out : out word_t;
        carry : out std_logic;
        overflow : out std_logic
    );
end entity;

architecture rtl of alu is
    alias shift_amount is in_2(SHIFT_AMOUNT_BITS - 1 downto 0);

    -- Shift fill value, will be '0' on logical shifts and
    -- will correspond to the sign bit on arithmetic shifts
    signal shift_fill : std_logic;
    signal barrel_in, barrel_out : word_t;

    -- carryin and second input depend on whether the operation
    -- is addition or subtraction
    signal carryin, adder_carry, adder_overflow : std_logic;
    signal adder_in2, adder_out: word_t;
begin
    shifter : entity work.barrel_shifter port map (
        d_in => in_1,
        amount => shift_amount,
        rot => rot,
        fill => shift_fill,
        d_out => barrel_out
    );

    adder : entity work.adder port map (
        d_in1 => in_1,
        d_in2 => adder_in2,
        cin => carryin,
        wrd => wrd,
        d_out => adder_out,
        cout => adder_carry,
        overflow => adder_overflow
    );

    do_op : process(all) is
    begin
        barrel_in <= in_1;
        shift_fill <= '0';

        carry <= '0';
        overflow <= '0';
        
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
            when OP_ADD =>
                adder_in2 <= in_2;
                carryin <= '0';
                d_out <= adder_out;
                carry <= adder_carry;
                overflow <= adder_overflow;
            when OP_SUB =>
                -- a - b = a + (~b + 1)
                adder_in2 <= not in_2;
                carryin <= '1';
                d_out <= adder_out;
                carry <= adder_carry;
                overflow <= adder_overflow;
            when OP_AND =>
                d_out <= in_1 and in_2;
            when OP_OR =>
                d_out <= in_1 or in_2;
            when OP_XOR =>
                d_out <= in_1 xor in_2;
            when OP_NOT =>
                d_out <= not in_1;
            when OP_MOV =>
                -- the output is the second input
                d_out <= in_2;
            -- XXX
            when others =>
        end case;
    end process;
end architecture;
