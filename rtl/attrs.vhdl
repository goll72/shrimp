library ieee;

use ieee.std_logic_1164.all;
use ieee.math_real.log2;

package attrs is
    constant WORD_BITS : natural := 16;
    constant BYTE_BITS : natural := 8;
    constant SHIFT_AMOUNT_BITS : natural := 4;
    constant IRQ_LINE_BITS : natural := 5;
    constant MSB : natural := 15;

    -- bit offsets in the instruction register
    constant IMM_BIT : natural := 6;
    constant WRD_BIT : natural := 5;
    constant SGN_BIT : natural := 4;
    constant ROT_BIT : natural := 4;
    constant N_BIT : natural := 5;
    constant Z_BIT : natural := 4;
    constant P_BIT : natural := 3;
    constant C_BIT : natural := 2;
    constant O_BIT : natural := 1;
    constant CALL_BIT : natural := 0;
    constant RETI_BIT : natural := 10;

    -- bit offsets in the flags register
    constant FLAG_N_BIT : natural := 15;
    constant FLAG_Z_BIT : natural := 14;
    constant FLAG_P_BIT : natural := 13;
    constant FLAG_C_BIT : natural := 12;
    constant FLAG_O_BIT : natural := 11;
    constant FLAG_IEN_BIT : natural := 10;

    -- IR ranges
    subtype opcode_range is natural range 15 downto 11;
    subtype reg1_range is natural range 10 downto 7;
    subtype reg2_range is natural range 3 downto 0;
    subtype imm_range is natural range 3 downto 0;
    subtype int_imm_range is natural range 4 downto 0;

    subtype word_t is std_logic_vector(WORD_BITS - 1 downto 0);
    subtype reg_addr_t is std_logic_vector(4 downto 0);
    subtype opcode_t is std_logic_vector(4 downto 0);
    -- 5 bit interrupt request ID (since it can address 32 interrupt vectors)
    subtype irq_id_t is std_logic_vector(IRQ_LINE_BITS - 1 downto 0);
    subtype counter_t is integer range 0 to 15;
    -- word without the MSB
    subtype no_msb is natural range WORD_BITS - 2 downto 0;

    constant IMM_REG_ADDR : reg_addr_t := "11111";
    constant SP_ADDR : reg_addr_t := "01111";
    constant WORD_ONE : word_t := (0 => '1', others => '0'); -- the number one
    constant TWELVE_ZEROS : std_logic_vector(11 downto 0) := "000000000000";
    constant ELEVEN_ZEROS : std_logic_vector(10 downto 0) := "00000000000";
    constant WORD_FIFTEEN : word_t := "0000000000001111";
    -- PC offsets for interrupts
    constant WORD_HARD_OFF : word_t := "0000000000010000";
    constant WORD_SOFT_OFF : word_t := "0000000000110000";

    -- control signals
    type pc_in_sel_t is (
        PC_IN_SEL_PC_PP,   -- PC Plus Plus (plus one)
        PC_IN_SEL_IR_REG2, -- interrupt vector from IR (+ 0xF)
        PC_IN_SEL_REG1OUT, -- register 1 output (+ 0xF)
        PC_IN_SEL_REG2OUT, -- register 2 output directly
        PC_IN_SEL_MEM_OUT
    );

    type flags_in_sel_t is (
        FLAGS_IN_SEL_SELF,
        FLAGS_IN_SEL_NEW_ALU,
        FLAGS_IN_SEL_NEW_MEM,
        FLAGS_IN_SEL_NEW_HI,
        FLAGS_IN_SEL_NEW_LO
    );

    type mem_addr_sel_t is (
        MEM_ADDR_SEL_PC,
        MEM_ADDR_SEL_REG1OUT,
        MEM_ADDR_SEL_REG2OUT,
        MEM_ADDR_SEL_HARD_ID, -- hard interrupt id + 0x10
        MEM_ADDR_SEL_SOFT_ID  -- soft interrupt id + 0x30
    );

    type mem_in_sel_t is (
        MEM_IN_SEL_PC,
        MEM_IN_SEL_REG1OUT,
        MEM_IN_SEL_REG2OUT,
        MEM_IN_SEL_FLAGS
    );

    type reg_reg1addr_sel_t is (
        REG_REG1ADDR_SEL_REG_IMM, -- immediate register
        REG_REG1ADDR_SEL_IR_REG1, -- first register operand in IR
        REG_REG1ADDR_SEL_IR_REG2, -- second register operand in IR
        REG_REG1ADDR_SEL_REG_SP
    );

    type reg_reg2addr_sel_t is (
        REG_REG2ADDR_SEL_REG_IMM,
        REG_REG2ADDR_SEL_IR_REG1,
        REG_REG2ADDR_SEL_IR_REG2,
        REG_REG2ADDR_SEL_COUNTER
    );

    type reg_waddr_sel_t is (
        REG_WADDR_SEL_REG_IMM,
        REG_WADDR_SEL_IR_REG1,
        REG_WADDR_SEL_REG_SP
    );

    type reg_in_sel_t is (
        REG_IN_SEL_MEM_OUT,
        REG_IN_SEL_ALU_OUT,
        REG_IN_SEL_FLAGS,   -- flags register output
        REG_IN_SEL_IR_IMM,
        REG_IN_SEL_SP_MM    -- SP Minus Minus (sp - 1)
    );

    type alu_opname_sel_t is (
        ALU_OPNAME_SEL_IR,
        ALU_OPNAME_SEL_ADD,
        ALU_OPNAME_SEL_SUB
    );

    type alu_in1_sel_t is (
        ALU_IN1_SEL_REG1OUT
    );

    type alu_in2_sel_t is (
        ALU_IN2_SEL_REG2OUT,
        ALU_IN2_SEL_ONE       -- the number one
    );

    type irc_soft_id_sel_t is (
        IRC_SOFT_ID_SEL_IR_IMM,
        IRC_SOFT_ID_SEL_REG1OUT,
        IRC_SOFT_ID_SEL_NOTHING
    );

    type ctrl_t is record
        pc_in_sel        : pc_in_sel_t;
        pc_w             : std_logic;

        ir_w             : std_logic;

        flags_in_n_sel   : flags_in_sel_t;
        flags_w_n        : std_logic;
        flags_in_z_sel   : flags_in_sel_t;
        flags_w_z        : std_logic;
        flags_in_p_sel   : flags_in_sel_t;
        flags_w_p        : std_logic;
        flags_in_c_sel   : flags_in_sel_t;
        flags_w_c        : std_logic;
        flags_in_o_sel   : flags_in_sel_t;
        flags_w_o        : std_logic;
        flags_in_ien_sel : flags_in_sel_t;
        flags_w_ien      : std_logic;
        flags_w_all      : std_logic;

        mem_addr_sel     : mem_addr_sel_t;
        mem_in_sel       : mem_in_sel_t;
        mem_r            : std_logic;
        mem_w            : std_logic;
        mem_en           : std_logic;

        reg_reg1addr_sel : reg_reg1addr_sel_t;
        reg_reg2addr_sel : reg_reg2addr_sel_t;
        reg_waddr_sel    : reg_waddr_sel_t;
        reg_in_sel       : reg_in_sel_t;
        reg_word         : std_logic;
        reg_w            : std_logic;

        alu_opname_sel   : alu_opname_sel_t;
        alu_in1_sel      : alu_in1_sel_t;
        alu_in2_sel      : alu_in2_sel_t;
        alu_sign         : std_logic;
        alu_rot          : std_logic;
        alu_word         : std_logic;
        alu_en           : std_logic;

        irc_soft_irq     : std_logic;
        irc_soft_id_sel  : irc_soft_id_sel_t;
    end record;
end package;
