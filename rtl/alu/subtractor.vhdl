library ieee;

use ieee.std_logic_1164.all;

use work.attrs.all;

entity subtractor is
    port (
        d_in1 : in word_t;
        d_in2 : in word_t;
        b_in  : in std_logic;
        result : out word_t;
        b_out : out std_logic
    );
end entity;

architecture dataflow of subtractor is
    signal borrows : std_logic_vector(WORD_BITS downto 0);
begin
    borrows(0) <= b_in;

    csm : for i in d_in1'range generate
        result(i) <= d_in1(i) xor d_in2(i) xor borrows(i);
        borrows(i + 1) <= borrows(i) and ((not d_in1(i)) or d_in2(i)) or ((not d_in1(i)) and d_in2(i));
    end generate;

    b_out <= borrows(borrows'high);
end architecture;

