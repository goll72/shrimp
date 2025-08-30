library ieee;
use ieee.std_logic_1164.all;

use work.attrs.all;


-- interrupt request controller
entity irc is
    port (
        hard_irq, soft_irq : in std_logic;
        hard_id, soft_id   : in irq_id_t;
        claim, en, rst     : in std_logic;
        asserted_irq  : out std_logic;
        asserted_hard : out std_logic;
        asserted_id   : out irq_id_t
    );
end entity;

architecture behavioral of irc is
    signal latched_irq  : std_logic;
    signal latched_hard : std_logic;
    signal latched_id   : irq_id_t;

    signal ready : std_logic;
begin
    -- only signal that should be gated on enable is irq
    -- the other signals may be used in the interrupt control cycle
    asserted_irq <= latched_irq when en = '1' else '0';
    asserted_hard <= latched_hard;
    asserted_id <= latched_id;
    -- IRC is ready to handle interrupts when nothing is latched
    ready <= not latched_irq;

    process (all)
    begin
        if rst = '1' then
            latched_irq <= '0';
            latched_hard <= '0';
            latched_id <= (others => '0');
        elsif en = '1' then
            if claim = '1' and ready = '0' then
                latched_irq <= '0';
                latched_hard <= '0';
                latched_id <= (others => '0');
            -- interrupts will be masked if there is already one latched
            elsif ready = '1' then
                if hard_irq = '1' then
                    latched_irq <= '1';
                    latched_hard <= '1';
                    latched_id <= hard_id;
                elsif soft_irq = '1' then
                    latched_irq <= '1';
                    latched_hard <= '0';
                    latched_id <= soft_id;
                end if;
            end if;
        end if;
    end process;
end architecture;
