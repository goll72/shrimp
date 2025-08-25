library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.attrs.all;
use work.opcode.all;

entity cpu is
    port (
        clk, rst : in std_logic;
        d_in : in word_t;
        d_out : out word_t
    );
end entity;

architecture structural of cpu is
    signal ctrl : ctrl_t;
    signal ir, ir_in, ir_ivec : word_t;
    signal pc, pc_in, pc_pp : word_t;
    signal mem_in, mem_out, mem_addr : word_t;
    signal reg_waddr, reg1addr, reg2addr : reg_addr_t;
    signal reg_in, reg1out, reg2out, reg1_ivec : word_t;
    signal alu_op : opcode_t;
    signal alu_in1, alu_in2, alu_out : word_t;
    signal alu_c, alu_o : std_logic;

    signal flags : word_t; -- TODO
begin
    IR_reg : entity work.reg port map (
        clk => clk,
        rst => rst,
        w_en => ctrl.ir_w,
        q => ir,
        d => ir_in
    );

    PC_reg : entity work.reg port map (
        clk => clk,
        rst => rst,
        w_en => ctrl.pc_w,
        q => pc,
        d => pc_in
    );

    RAM : entity work.memory port map (
        clk => not clk, -- trigger on falling edge instead
        en => ctrl.mem_en,
        r => ctrl.mem_r,
        w => ctrl.mem_w,
        addr => mem_addr,
        d_in => mem_in,
        d_out => mem_out
    );

    GPRs : entity work.reg_file port map (
        clk => clk,
        rst => rst,
        w_en => ctrl.reg_w,
        w_word => ctrl.alu_word,
        w_addr => reg_waddr,
        w_data => reg_in,
        reg1_addr => reg1addr,
        reg2_addr => reg2addr,
        reg1 => reg1out,
        reg2 => reg2out
    );

    ALU : entity work.alu port map (
        op => alu_op,
        in_1 => alu_in1,
        in_2 => alu_in2,
        sgn => ctrl.alu_sign,
        rot => ctrl.alu_rot,
        wrd => ctrl.alu_word,
        d_out => alu_out,
        carry => alu_c,
        overflow => alu_o
    );

    control : entity work.control port map (
        clk => clk,
        rst => rst,
        ir => ir,
        memout => mem_out,
        flags => flags,
        ctrl => ctrl
    );

    PC_plus_one : entity work.adder port map (
        d_in1 => pc,
        d_in2 => (others => '0'),
        cin => '1',
        wrd => '1',
        d_out => pc_pp,
        cout => open,
        overflow => open
    );

    -- interrupt vector from IR
    IR_intr_vec : entity work.adder port map (
        d_in1 => TWELVE_ZEROS & ir(imm_range),
        d_in2 => WORD_FIFTEEN,
        cin => '0',
        wrd => '1',
        d_out => ir_ivec,
        cout => open,
        overflow => open
    );

    REG1_intr_vec : entity work.adder port map (
        d_in1 => reg1out,
        d_in2 => WORD_FIFTEEN,
        cin => '0',
        wrd => '1',
        d_out => reg1_ivec,
        cout => open,
        overflow => open
    );

    -- IR will only ever be fetched from memory
    ir_in <= mem_out;

    with ctrl.pc_in_sel select pc_in <=
        pc_pp when PC_IN_SEL_PC_PP,
        ir_ivec when PC_IN_SEL_IR_REG2,
        reg1_ivec when PC_IN_SEL_REG1OUT,
        reg2out when PC_IN_SEL_REG2OUT,
        mem_out when PC_IN_SEL_MEM_OUT;

    -- with ctrl.flags_in_sel select ...

    with ctrl.mem_addr_sel select mem_addr <=
        pc when MEM_ADDR_SEL_PC,
        reg1out when MEM_ADDR_SEL_REG1OUT,
        reg2out when MEM_ADDR_SEL_REG2OUT;

    with ctrl.mem_in_sel select mem_in <=
        pc when MEM_IN_SEL_PC,
        reg1out when MEM_IN_SEL_REG1OUT;

    with ctrl.reg_reg1addr_sel select reg1addr <=
        IMM_REG_ADDR when REG_REG1ADDR_SEL_REG_IMM,
        '0' & ir(reg1_range) when REG_REG1ADDR_SEL_IR_REG1,
        '0' & ir(reg2_range) when REG_REG1ADDR_SEL_IR_REG2,
        SP_ADDR when REG_REG1ADDR_SEL_REG_SP;

    with ctrl.reg_reg2addr_sel select reg2addr <=
        IMM_REG_ADDR when REG_REG2ADDR_SEL_REG_IMM,
        '0' & ir(reg1_range) when REG_REG2ADDR_SEL_IR_REG1,
        '0' & ir(reg2_range) when REG_REG2ADDR_SEL_IR_REG2;

    with ctrl.reg_waddr_sel select reg_waddr <=
        IMM_REG_ADDR when REG_WADDR_SEL_REG_IMM,
        '0' & ir(reg1_range) when REG_WADDR_SEL_IR_REG1,
        SP_ADDR when REG_WADDR_SEL_REG_SP;

    with ctrl.reg_in_sel select reg_in <=
        mem_out when REG_IN_SEL_MEM_OUT,
        alu_out when REG_IN_SEL_ALU_OUT,
        flags when REG_IN_SEL_FLAGS,
        TWELVE_ZEROS & ir(imm_range) when REG_IN_SEL_IR_IMM,
        (others => '0') when REG_IN_SEL_SP_MM; -- TODO

    with ctrl.alu_opname_sel select alu_op <=
        ir(opcode_range) when ALU_OPNAME_SEL_IR,
        OP_ADD when ALU_OPNAME_SEL_ADD,
        OP_SUB when ALU_OPNAME_SEL_SUB;

    with ctrl.alu_in1_sel select alu_in1 <=
        reg1out when ALU_IN1_SEL_REG1OUT;

    with ctrl.alu_in2_sel select alu_in2 <=
        reg2out when ALU_IN2_SEL_REG2OUT,
        WORD_ONE when ALU_IN2_SEL_ONE;
end architecture;
