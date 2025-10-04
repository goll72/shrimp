library ieee;
use ieee.std_logic_1164.all;

use work.attrs.all;

entity magnitude is
    port (
        d_in1 : in word_t;
        sgn : in std_logic; -- signed operation flag
        wrd : in std_logic;
        d_out : out word_t;
        signb : out std_logic -- sign bit
    );
end entity;

architecture structural of magnitude is
    -- arithmetic inverse of the input
    signal in_neg : word_t;
begin
    negator : entity work.adder port map (
        d_in1 => not d_in1,
        d_in2 => (others => '0'),
        cin => '1',
        wrd => '1',
        d_out => in_neg,
        cout => open,
        overflow => open
    );

    process (all)
        variable msb : natural;
    begin
        if wrd = '1' then
            msb := WORD_BITS - 1;
        else
            msb := BYTE_BITS - 1;
        end if;

        if sgn = '1' then
            signb <= d_in1(msb);

            if d_in1(msb) = '1' then
                d_out <= in_neg;
            else
                d_out <= d_in1;
            end if;
        else
            signb <= '0';
            d_out <= d_in1;
        end if;
    end process;
end architecture;
