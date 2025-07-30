library ieee;
use ieee.std_logic_1164.all;

use work.attrs.all;
use work.opcode.all;

entity control is
    port (
        clk, rst : in std_logic;
        ir   : in word_t; -- instruction register
        flags: in word_t; -- flags register
        ctrl : out ctrl_t
    );
end entity;

architecture dataflow of control is
    type state_t is (
        s_reset,
        s_fetch,
        s_wait,
        s_decode,
        s_alu,
        s_alu2,
        s_jmp,
        s_jmp2,
        s_jmp_push_pc,
        s_jmp_push_pc_fetch_imm,
        s_jmp_push_pc_finish,
        s_ret,
        s_int,
        s_ld,
        s_ld2,
        s_st,
        s_st2,
        s_ldflg,
        s_stflg,
        s_bad
    );

    alias opcode is ir(opcode_range);
    alias imm is ir(IMM_BIT);
    alias wrd is ir(WRD_BIT);
    alias sgn is ir(SGN_BIT);
    alias rot is ir(ROT_BIT);
    alias n is ir(N_BIT);
    alias z is ir(Z_BIT);
    alias p is ir(P_BIT);
    alias c is ir(C_BIT);
    alias o is ir(O_BIT);
    alias call is ir(CALL_BIT);

    alias flag_n is flags(FLAG_N_BIT);
    alias flag_z is flags(FLAG_Z_BIT);
    alias flag_p is flags(FLAG_P_BIT);
    alias flag_c is flags(FLAG_C_BIT);
    alias flag_o is flags(FLAG_O_BIT);

    signal state : state_t;

    function shifty(opc : opcode_t) return boolean is
    begin
        return opc = OP_SHA or opc = OP_SHL or opc = OP_SHR;
    end function;

    -- initialize all the signals, prevents latching
    -- most assignments are arbitary, enable signals are forced low
    procedure init_signals(signal ctrl : inout ctrl_t) is
    begin
        ctrl.pc_in_sel <= PC_IN_SEL_PC_PP;
        ctrl.pc_w <= '0';
        ctrl.ir_w <= '0';
        ctrl.flags_in_n_sel <= FLAGS_IN_SEL_SELF;
        ctrl.flags_in_z_sel <= FLAGS_IN_SEL_SELF;
        ctrl.flags_in_p_sel <= FLAGS_IN_SEL_SELF;
        ctrl.flags_in_c_sel <= FLAGS_IN_SEL_SELF;
        ctrl.flags_in_o_sel <= FLAGS_IN_SEL_SELF;
        ctrl.flags_w <= '0';
        ctrl.mem_addr_sel <= MEM_ADDR_SEL_PC;
        ctrl.mem_in_sel <= MEM_IN_SEL_REG1OUT;
        ctrl.mem_r <= '0';
        ctrl.mem_w <= '0';
        ctrl.mem_en <= '0';
        ctrl.reg_reg1addr_sel <= REG_REG1ADDR_SEL_IR_REG1;
        ctrl.reg_reg2addr_sel <= REG_REG2ADDR_SEL_IR_REG2;
        ctrl.reg_waddr_sel <= REG_WADDR_SEL_REG_IMM;
        ctrl.reg_in_sel <= REG_IN_SEL_IR_IMM;
        ctrl.reg_word <= '0';
        ctrl.reg_w <= '0';
        ctrl.alu_opname_sel <= ALU_OPNAME_SEL_IR;
        ctrl.alu_in1_sel <= ALU_IN1_SEL_REG1OUT;
        ctrl.alu_in2_sel <= ALU_IN2_SEL_REG2OUT;
        ctrl.alu_sign <= '0';
        ctrl.alu_rot <= '0';
        ctrl.alu_word <= '0';
        ctrl.alu_en <= '0';
    end procedure;

    procedure fetch_imm(signal ctrl : inout ctrl_t ; opcode : opcode_t) is
    begin
        ctrl.flags_w <= '0';
        ctrl.alu_en <= '0';
        if shifty(opcode) then
            ctrl.pc_w <= '0';
            ctrl.ir_w <= '0';
            ctrl.mem_en <= '0';
            ctrl.reg_in_sel <= REG_IN_SEL_IR_IMM;
        else
            -- increment PC (after getting imm)
            ctrl.pc_in_sel <= PC_IN_SEL_PC_PP;
            ctrl.pc_w <= '1';
            ctrl.ir_w <= '0';
            ctrl.mem_addr_sel <= MEM_ADDR_SEL_PC;
            ctrl.mem_w <= '0';
            ctrl.mem_r <= '1';
            ctrl.mem_en <= '1';
            ctrl.reg_in_sel <= REG_IN_SEL_MEM_OUT;
        end if;
        ctrl.reg_waddr_sel <= REG_WADDR_SEL_REG_IMM;
        ctrl.reg_w <= '1';
        ctrl.reg_word <= '1';
    end procedure;

    procedure complete_alu_op(signal ctrl : inout ctrl_t ; ir : word_t) is
        alias wrd is ir(WRD_BIT);
        alias sgn is ir(SGN_BIT);
        alias rot is ir(ROT_BIT);
    begin
        ctrl.pc_w <= '0';
        ctrl.ir_w <= '0';
        ctrl.mem_en <= '0';
        -- reg2addr will be selected before this procedure runs (same state)
        ctrl.reg_reg1addr_sel <= REG_REG1ADDR_SEL_IR_REG1;
        ctrl.reg_word <= wrd;
        ctrl.reg_waddr_sel <= REG_WADDR_SEL_IR_REG1;
        ctrl.reg_in_sel <= REG_IN_SEL_ALU_OUT;
        ctrl.reg_w <= '1';
        -- alu
        ctrl.alu_opname_sel <= ALU_OPNAME_SEL_IR;
        ctrl.alu_in1_sel <= ALU_IN1_SEL_REG1OUT;
        ctrl.alu_in2_sel <= ALU_IN2_SEL_REG2OUT;
        ctrl.alu_sign <= sgn;
        ctrl.alu_rot <= rot;
        ctrl.alu_word <= wrd;
        ctrl.alu_en <= '1';
        -- flags
        ctrl.flags_in_n_sel <= FLAGS_IN_SEL_NEW_ALU;
        ctrl.flags_in_z_sel <= FLAGS_IN_SEL_NEW_ALU;
        ctrl.flags_in_p_sel <= FLAGS_IN_SEL_NEW_ALU;
        ctrl.flags_in_c_sel <= FLAGS_IN_SEL_NEW_ALU;
        ctrl.flags_in_o_sel <= FLAGS_IN_SEL_NEW_ALU;
        ctrl.flags_w <= '1';
    end procedure;

    procedure complete_load(signal ctrl : inout ctrl_t) is
    begin
        ctrl.pc_w <= '0';
        ctrl.ir_w <= '0';
        -- flags
        ctrl.flags_in_n_sel <= FLAGS_IN_SEL_NEW_MEM;
        ctrl.flags_in_z_sel <= FLAGS_IN_SEL_NEW_MEM;
        ctrl.flags_in_p_sel <= FLAGS_IN_SEL_NEW_MEM;
        ctrl.flags_in_c_sel <= FLAGS_IN_SEL_SELF;
        ctrl.flags_in_o_sel <= FLAGS_IN_SEL_SELF;
        ctrl.flags_w <= '1';
        -- memory
        ctrl.mem_addr_sel <= MEM_ADDR_SEL_REG2OUT;
        ctrl.mem_r <= '1';
        ctrl.mem_w <= '0';
        ctrl.mem_en <= '1';
        -- register
        ctrl.reg_waddr_sel <= REG_WADDR_SEL_IR_REG1;
        ctrl.reg_in_sel <= REG_IN_SEL_MEM_OUT;
        ctrl.reg_word <= '1';
        ctrl.reg_w <= '1';
        ctrl.alu_en <= '0';
    end procedure;

    procedure complete_store(signal ctrl : inout ctrl_t) is
    begin
        ctrl.pc_w <= '0';
        ctrl.ir_w <= '0';
        ctrl.flags_w <= '0';
        -- memory
        ctrl.mem_addr_sel <= MEM_ADDR_SEL_REG2OUT;
        ctrl.mem_in_sel <= MEM_IN_SEL_REG1OUT;
        ctrl.mem_r <= '0';
        ctrl.mem_w <= '1';
        ctrl.mem_en <= '1';
        -- register
        ctrl.reg_reg1addr_sel <= REG_REG1ADDR_SEL_IR_REG1;
        ctrl.reg_word <= '1';
        ctrl.reg_w <= '0';
        ctrl.alu_en <= '0';
    end procedure;

    -- decrement stack pointer
    procedure complete_jmp_dec_sp(signal ctrl : inout ctrl_t) is
    begin
        ctrl.pc_w <= '0';
        ctrl.ir_w <= '0';
        ctrl.flags_w <= '0';
        ctrl.mem_en <= '0';
        -- register
        ctrl.reg_reg1addr_sel <= REG_REG1ADDR_SEL_REG_SP;
        ctrl.reg_waddr_sel <= REG_WADDR_SEL_REG_SP;
        ctrl.reg_in_sel <= REG_IN_SEL_ALU_OUT;
        ctrl.reg_word <= '1';
        ctrl.reg_w <= '1';
        -- alu
        ctrl.alu_opname_sel <= ALU_OPNAME_SEL_SUB;
        ctrl.alu_in1_sel <= ALU_IN1_SEL_REG1OUT;
        ctrl.alu_in2_sel <= ALU_IN2_SEL_ONE;
        ctrl.alu_sign <= '0';
        ctrl.alu_word <= '1';
        ctrl.alu_en <= '1';
    end procedure;

    -- push PC to stack
    procedure complete_jmp_push_pc(signal ctrl : inout ctrl_t) is
    begin
        ctrl.pc_w <= '0';
        ctrl.ir_w <= '0';
        ctrl.flags_w <= '0';
        -- memory
        ctrl.mem_addr_sel <= MEM_ADDR_SEL_REG1OUT;
        ctrl.mem_in_sel <= MEM_IN_SEL_PC;
        ctrl.mem_w <= '1';
        ctrl.mem_r <= '0';
        ctrl.mem_en <= '1';
        -- register
        ctrl.reg_reg1addr_sel <= REG_REG1ADDR_SEL_REG_SP;
        ctrl.reg_word <= '1';
        ctrl.reg_w <= '0';
        ctrl.alu_en <= '0';
    end procedure;

    procedure complete_jmp(signal ctrl : inout ctrl_t) is
    begin
        ctrl.pc_in_sel <= PC_IN_SEL_REG2OUT;
        ctrl.pc_w <= '1';
        ctrl.ir_w <= '0';
        ctrl.flags_w <= '0';
        ctrl.mem_en <= '0';
        ctrl.reg_word <= '1';
        ctrl.reg_w <= '0';
    end procedure;
begin
    process (clk) is
        variable next_state : state_t;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                next_state := s_reset;
            end if;

            init_signals(ctrl);

            state <= next_state;
            case next_state is
                when s_reset =>
                    next_state := s_fetch;
                when s_fetch =>
                    -- IR <= [PC++]
                    ctrl.pc_in_sel <= PC_IN_SEL_PC_PP;
                    ctrl.pc_w <= '1';
                    ctrl.ir_w <= '1'; -- IR input is always mem.out
                    ctrl.flags_w <= '0';
                    ctrl.mem_addr_sel <= MEM_ADDR_SEL_PC;
                    ctrl.mem_r <= '1';
                    ctrl.mem_w <= '0';
                    ctrl.mem_en <= '1';
                    ctrl.reg_w <= '0';
                    ctrl.alu_en <= '0';
                    next_state := s_wait;
                when s_wait =>
                    next_state := s_decode;
                when s_decode =>
                    with opcode select next_state :=
                        s_alu when OP_ADD,
                        s_alu when OP_SUB,
                        s_alu when OP_MUL,
                        s_alu when OP_DIV,
                        s_alu when OP_SHA,
                        s_alu when OP_AND,
                        s_alu when OP_OR,
                        s_alu when OP_XOR,
                        s_alu when OP_NOT,
                        s_alu when OP_SHL,
                        s_alu when OP_SHR,
                        s_alu when OP_MOV,
                        s_jmp when OP_JMP,
                        s_ret when OP_RET,
                        s_int when OP_INT,
                        s_ld  when OP_LD,
                        s_st  when OP_ST,
                        s_ldflg when OP_LDFLG,
                        s_stflg when OP_STFLG,
                        s_bad when others;
                when s_alu =>
                    if imm = '1' then
                        fetch_imm(ctrl, opcode);
                        next_state := s_alu2;
                    else
                        ctrl.reg_reg2addr_sel <= REG_REG2ADDR_SEL_IR_REG2;
                        complete_alu_op(ctrl, ir);
                        next_state := s_fetch;
                    end if;
                when s_alu2 =>
                    ctrl.reg_reg2addr_sel <= REG_REG2ADDR_SEL_REG_IMM;
                    complete_alu_op(ctrl, ir);
                    next_state := s_fetch;
                when s_jmp =>
                    -- jump when one flag matches or when none are set
                    if n = flag_n or z = flag_z or p = flag_p
                    or c = flag_c or o = flag_o or (or(n&z&p&c&o)) = '0' then
                        if call = '1' then
                            complete_jmp_dec_sp(ctrl);
                            next_state := s_jmp_push_pc;
                        elsif imm = '1' then
                            fetch_imm(ctrl, opcode);
                            next_state := s_jmp2;
                        else
                            ctrl.reg_reg2addr_sel <= REG_REG2ADDR_SEL_IR_REG2;
                            complete_jmp(ctrl);
                            next_state := s_fetch;
                        end if;
                    else
                        next_state := s_fetch;
                    end if;
                when s_jmp2 =>
                     ctrl.reg_reg2addr_sel <= REG_REG2ADDR_SEL_REG_IMM;
                     complete_jmp(ctrl);
                     next_state := s_fetch;
                when s_jmp_push_pc =>
                    complete_jmp_push_pc(ctrl);
                    if imm = '1' then
                        next_state := s_jmp_push_pc_fetch_imm;
                    else
                        next_state := s_jmp_push_pc_finish;
                    end if;
                when s_jmp_push_pc_fetch_imm =>
                    fetch_imm(ctrl, opcode);
                    next_state := s_jmp2;
                when s_jmp_push_pc_finish =>
                    ctrl.reg_reg2addr_sel <= REG_REG2ADDR_SEL_IR_REG2;
                    complete_jmp(ctrl);
                    next_state := s_fetch;
                when s_ret =>
                when s_int =>
                when s_ld =>
                    if imm = '1' then
                        fetch_imm(ctrl, opcode);
                        next_state := s_ld2;
                    else
                        ctrl.reg_reg2addr_sel <= REG_REG2ADDR_SEL_IR_REG2;
                        complete_load(ctrl);
                        next_state := s_fetch;
                    end if;
                when s_ld2 =>
                    ctrl.reg_reg2addr_sel <= REG_REG2ADDR_SEL_REG_IMM;
                    complete_load(ctrl);
                    next_state := s_fetch;
                when s_st =>
                    if imm = '1' then
                        fetch_imm(ctrl, opcode);
                        next_state := s_st2;
                    else
                        ctrl.reg_reg2addr_sel <= REG_REG2ADDR_SEL_IR_REG2;
                        complete_store(ctrl);
                        next_state := s_fetch;
                    end if;
                when s_st2 =>
                    ctrl.reg_reg2addr_sel <= REG_REG2ADDR_SEL_REG_IMM;
                    complete_store(ctrl);
                    next_state := s_fetch;
                when s_ldflg =>
                    ctrl.pc_w <= '0';
                    ctrl.ir_w <= '0';
                    ctrl.flags_w <= '0';
                    ctrl.mem_en <= '0';
                    ctrl.reg_waddr_sel <= REG_WADDR_SEL_IR_REG1;
                    ctrl.reg_in_sel <= REG_IN_SEL_FLAGS;
                    ctrl.reg_word <= '1';
                    ctrl.reg_w <= '1';
                    ctrl.alu_en <= '0';
                    next_state := s_fetch;
                when s_stflg =>
                    ctrl.pc_w <= '0';
                    ctrl.ir_w <= '0';
                    ctrl.flags_in_n_sel <= FLAGS_IN_SEL_NEW_REG1OUT;
                    ctrl.flags_in_z_sel <= FLAGS_IN_SEL_NEW_REG1OUT;
                    ctrl.flags_in_p_sel <= FLAGS_IN_SEL_NEW_REG1OUT;
                    ctrl.flags_in_c_sel <= FLAGS_IN_SEL_NEW_REG1OUT;
                    ctrl.flags_in_o_sel <= FLAGS_IN_SEL_NEW_REG1OUT;
                    ctrl.flags_w <= '1';
                    ctrl.mem_en <= '0';
                    ctrl.reg_reg1addr_sel <= REG_REG1ADDR_SEL_IR_REG1;
                    ctrl.reg_word <= '1';
                    ctrl.reg_w <= '0';
                    next_state := s_fetch;
                when s_bad =>
                    -- uh oh...
                when others =>
                    -- XXX
            end case;
        end if;
    end process;
end architecture;
