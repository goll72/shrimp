library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.attrs.all;

entity reg_file is
    port (
        clk, rst     : in std_logic;
        w_en, w_word : in std_logic;
        w_addr       : in reg_addr_t;
        w_data       : in word_t;
        reg1_addr, reg2_addr : in reg_addr_t;
        reg1, reg2   : out word_t
    );
end entity;

architecture behavioral of reg_file is
    -- 16 general-purpose registers + immediate register.
    --
    -- The immediate register is accessed by setting addr to "1----".
    constant N_REGS : natural := 17;
    constant IMM_BIT : natural := 4;
    
    type reg_t is array(N_REGS - 1 downto 0) of word_t;

    signal regs : reg_t;

    signal reg_w  : std_logic_vector(N_REGS - 1 downto 0);
    signal reg1_r : std_logic_vector(N_REGS - 1 downto 0);
    signal reg2_r : std_logic_vector(N_REGS - 1 downto 0);

    function equals(i: natural; v: std_logic_vector) return std_logic is
    begin
        if std_logic_vector(to_unsigned(i, v'length)) = v then
            return '1';
        else
            return '0';
        end if;
    end function;
begin
    process(clk, rst, w_en) is
    begin
        if rst = '1' then
            regs <= (others => (others => '0'));
        elsif rising_edge(clk) and w_en = '1' then
            for i in 0 to N_REGS - 1 loop
                if reg_w(i) = '1' then
                    if w_word = '1' then
                        regs(i)(15 downto 8) <= w_data(15 downto 8);
                    end if;
                
                    regs(i)(7 downto 0) <= w_data(7 downto 0);
                end if;
            end loop;
        end if;
    end process;

    -- The bit corresponding to the immediate register
    -- passes through, the others are decoded.
    reg_w(N_REGS - 1) <= w_addr(IMM_BIT);
    reg1_r(N_REGS - 1) <= reg1_addr(IMM_BIT);
    reg2_r(N_REGS - 1) <= reg2_addr(IMM_BIT);

    decoders : for i in 0 to N_REGS - 2 generate
        reg_w(i) <= equals(i, w_addr) and not w_addr(IMM_BIT);
        reg1_r(i) <= equals(i, reg1_addr) and not reg1_addr(IMM_BIT);
        reg2_r(i) <= equals(i, reg2_addr) and not reg2_addr(IMM_BIT);
    end generate;

    read : for i in 0 to N_REGS - 1 generate
        reg1 <= regs(i) when reg1_r(i) = '1' else (others => 'Z');
        reg2 <= regs(i) when reg2_r(i) = '1' else (others => 'Z');
    end generate;
end architecture;
