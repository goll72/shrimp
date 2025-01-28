library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.attrs.all;

entity barrel_shifter is
    port (
        d_in : in word_t;
        amount : in std_logic_vector(SHIFT_AMOUNT_BITS - 1 downto 0);
        rot : in std_logic;
        fill : in std_logic;
        d_out : out word_t
    );
end entity;

architecture behavioral of barrel_shifter is
    -- Shift amount, decoded
    signal shift : word_t;
    
    signal tmp, mask : word_t;
begin
    decode_shift : for i in shift'range generate
        shift(i) <= '1' when to_integer(unsigned(amount)) = i else '0';
    end generate;

    barrel : for i in shift'range generate
        tbufs : for j in tmp'range generate
           tmp((i + j) mod tmp'length) <= d_in(j) when shift(i) = '1' else 'Z';
       end generate;
    end generate;

    shift_mask : for i in mask'range generate
        mask(i) <= or(shift(i downto 1)) or rot;
    end generate;

    output : for i in d_out'range generate
        d_out(i) <= tmp(i) when mask(i) = '1' else fill;
    end generate;
end architecture;
