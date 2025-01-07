// MIPS Processor Implementation in Verilog
// ALU Unit
module alu_unit (
    input [31:0] operand_a, operand_b,
    input [2:0] operation_code,
    output reg [31:0] alu_output,
    output reg zero_flag
);
    wire signed [31:0] signed_a, signed_b;
    assign signed_a = operand_a;
    assign signed_b = operand_b;

    always @(*) begin
        case (operation_code)
            3'b000: alu_output = operand_a & operand_b;   // AND
            3'b001: alu_output = operand_a | operand_b;   // OR
            3'b010: alu_output = operand_a + operand_b;   // ADD
            3'b110: alu_output = operand_a - operand_b;   // SUB
            3'b111: alu_output = (signed_a < signed_b) ? 32'b1 : 32'b0; // SLT
            default: alu_output = 32'b0;
        endcase
        zero_flag = (alu_output == 32'b0);
    end
endmodule

// Control Decoder
module control_decoder (
    input [5:0] instr_opcode, funct_code,
    input zero_flag,
    output reg reg_write, 
    output reg [1:0] reg_dst,
    output reg alu_src, 
    output reg mem_read, 
    output reg mem_write, 
    output reg mem_to_reg, 
    output reg branch,
    output reg [2:0] alu_op
);
    always @(*) begin
        reg_write = 1'b0;
        alu_src = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        branch = 1'b0;
        reg_dst = 2'b00;
        alu_op = 3'b000;

        case (instr_opcode)
            6'b000000: begin // R-type
                reg_write = 1'b1;
                reg_dst = 2'b01;
                
                case (funct_code)
                    6'b100000: alu_op = 3'b010; // ADD
                    6'b100010: alu_op = 3'b110; // SUB
                    6'b100100: alu_op = 3'b000; // AND
                    6'b100101: alu_op = 3'b001; // OR
                    6'b101010: alu_op = 3'b111; // SLT
                    default:   alu_op = 3'b000;
                endcase
            end
            
            6'b100011: begin // LW
                reg_write = 1'b1;
                alu_src = 1'b1;
                mem_read = 1'b1;
                mem_to_reg = 1'b1;
                reg_dst = 2'b00;
                alu_op = 3'b010;
            end
            
            6'b101011: begin // SW
                alu_src = 1'b1;
                mem_write = 1'b1;
                alu_op = 3'b010;
            end
            
            6'b000100: begin // BEQ
                branch = zero_flag;
                alu_op = 3'b110;
            end
            
            default: begin
                alu_op = 3'b000;
            end
        endcase
    end
endmodule

// Instruction Memory
module instruction_memory (
    input [31:0] pc,
    output [31:0] instruction
);
    reg [31:0] memory [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'h0;
            
        memory[0] = 32'h00221820;  // ADD $3, $1, $2
        memory[1] = 32'h00612022;  // SUB $4, $3, $1
        memory[2] = 32'hAC040004;  // SW $4, 4($0)
        memory[3] = 32'h8C050004;  // LW $5, 4($0)
        memory[4] = 32'h10850004;  // BEQ $4, $5, 4
    end

    assign instruction = (pc[31:2] < 256) ? memory[pc[31:2]] : 32'bx;
endmodule

// Data Memory
module data_memory (
    input clk,
    input [31:0] address,
    input [31:0] write_data,
    input mem_read, 
    input mem_write,
    output reg [31:0] read_data
);
    reg [31:0] memory [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'h0;
            
        memory[0] = 32'h00000001;
        memory[1] = 32'h0000000a;
        memory[2] = 32'h00000003;
        memory[3] = 32'h00000004;
        memory[4] = 32'h0000000a;
    end

    always @(*) begin
        if (mem_read)
            read_data = memory[address[9:2]];
        else
            read_data = 32'bx;
    end

    always @(posedge clk) begin
        if (mem_write)
            memory[address[9:2]] = write_data;
    end
endmodule

// Register File
module register_file (
    input clk,
    input [4:0] read_reg1, read_reg2, write_reg,
    input [31:0] write_data,
    input reg_write,
    output [31:0] read_data1, read_data2
);
    reg [31:0] registers [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'b0;
            
        registers[1] = 32'h00000005;
        registers[2] = 32'h0000000A;
    end

    assign read_data1 = registers[read_reg1];
    assign read_data2 = registers[read_reg2];

    always @(posedge clk) begin
        if (reg_write && (write_reg != 5'b0))
            registers[write_reg] = write_data;
    end
endmodule

// Multiplexers
module mux5_2x1 (
    input [4:0] in_a, in_b,
    input select,
    output reg [4:0] out
);
    always @(*) begin
        out = select ? in_b : in_a;
    end
endmodule

module mux32_2x1 (
    input [31:0] in_a, in_b,
    input select,
    output reg [31:0] out
);
    always @(*) begin
        out = select ? in_b : in_a;
    end
endmodule

// Adders
module add_pc (
    input [31:0] current_pc,
    output reg [31:0] next_pc
);
    always @(*) begin
        next_pc = current_pc + 32'd4;
    end
endmodule

module add_branch (
    input [31:0] current_pc, branch_offset,
    output reg [31:0] branch_pc
);
    always @(*) begin
        branch_pc = current_pc + {{14{branch_offset[15]}}, branch_offset, 2'b00};
    end
endmodule

module sign_extender (
    input [15:0] immediate,
    output reg [31:0] extended_immediate
);
    always @(*) begin
        extended_immediate = {{16{immediate[15]}}, immediate};
    end
endmodule

// MIPS Processor Top-Level
module mips_processor (
    input clk, 
    input reset,
    output [31:0] pc_out,
    output [31:0] instruction_out,
    output [31:0] alu_result_out
);
    reg [31:0] pc;
    reg [31:0] prev_pc;

    wire [31:0] next_pc, instruction, reg_read_data1, reg_read_data2;
    wire [31:0] alu_result, mem_read_data, write_back_data;
    wire [31:0] sign_extended_immediate, branch_target, pc_plus_4, alu_input;
    wire [4:0] write_reg;
    wire [2:0] alu_op;
    wire zero_flag, branch;
    wire reg_write, alu_src, mem_read, mem_write, mem_to_reg;
    wire [1:0] reg_dst;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'b0;
            prev_pc <= 32'b0;
        end
        else begin
            pc <= next_pc;
            prev_pc <= pc;
        end
    end

    instruction_memory imem (
        .pc(pc),
        .instruction(instruction)
    );

    register_file regfile (
        .clk(clk),
        .read_reg1(instruction[25:21]),
        .read_reg2(instruction[20:16]),
        .write_reg(write_reg),
        .write_data(write_back_data),
        .reg_write(reg_write),
        .read_data1(reg_read_data1),
        .read_data2(reg_read_data2)
    );

    sign_extender signext (
        .immediate(instruction[15:0]),
        .extended_immediate(sign_extended_immediate)
    );

    mux5_2x1 reg_dest_mux (
        .in_a(instruction[20:16]),
        .in_b(instruction[15:11]),
        .select(reg_dst[0]),
        .out(write_reg)
    );

    mux32_2x1 alu_src_mux (
        .in_a(reg_read_data2),
        .in_b(sign_extended_immediate),
        .select(alu_src),
        .out(alu_input)
    );

    alu_unit alu (
        .operand_a(reg_read_data1),
        .operand_b(alu_input),
        .operation_code(alu_op),
        .alu_output(alu_result),
        .zero_flag(zero_flag)
    );

    data_memory dmem (
        .clk(clk),
        .address(alu_result),
        .write_data(reg_read_data2),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .read_data(mem_read_data)
    );

    wire branch_condition;
    assign branch_condition = (reg_read_data1 == reg_read_data2);

    mux32_2x1 mem_to_reg_mux (
        .in_a(alu_result),
        .in_b(mem_read_data),
        .select(mem_to_reg),
        .out(write_back_data)
    );

    control_decoder control (
        .instr_opcode(instruction[31:26]),
        .funct_code(instruction[5:0]),
        .zero_flag(branch_condition),
        .reg_write(reg_write),
        .reg_dst(reg_dst),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .alu_op(alu_op)
    );

    add_pc pc_adder (
        .current_pc(pc),
        .next_pc(pc_plus_4)
    );

    add_branch branch_adder (
        .current_pc(pc_plus_4),
        .branch_offset(sign_extended_immediate),
        .branch_pc(branch_target)
    );

    mux32_2x1 pc_mux (
        .in_a(pc_plus_4),
        .in_b(branch_target),
        .select(branch && branch_condition),
        .out(next_pc)
    );

    assign pc_out = pc;
    assign instruction_out = instruction;
    assign alu_result_out = alu_result;
endmodule

// Testbench
module mips_processor_tb;
    reg clk, reset;
    wire [31:0] pc, instruction, alu_result;
    wire [31:0] memory_data_0, memory_data_1, memory_data_2, memory_data_3, memory_data_4;

    mips_processor uut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc),
        .instruction_out(instruction),
        .alu_result_out(alu_result)
    );

    assign memory_data_0 = uut.dmem.memory[0];
    assign memory_data_1 = uut.dmem.memory[1];
    assign memory_data_2 = uut.dmem.memory[2];
    assign memory_data_3 = uut.dmem.memory[3];
    assign memory_data_4 = uut.dmem.memory[4];

    always #5 clk = ~clk;

    initial begin
        $display("Starting MIPS Processor Simulation");
        clk = 0;
        reset = 1;
        #15 reset = 0;
        #500 $finish;
    end

    initial begin
        $dumpfile("mips_processor_debug.vcd");
        $dumpvars(0, mips_processor_tb);
        $monitor("Time=%0t PC=%h Instruction=%h ALU Result=%h R1=%h R2=%h R3=%h R4=%h R5=%h Mem[0]=%h Mem[1]=%h Mem[2]=%h Mem[3]=%h Mem[4]=%h", 
                 $time, pc, instruction, alu_result,
                 uut.regfile.registers[1], 
                 uut.regfile.registers[2],
                 uut.regfile.registers[3],
                 uut.regfile.registers[4],
                 uut.regfile.registers[5],
                 memory_data_0, memory_data_1, memory_data_2, memory_data_3, memory_data_4);
    end
endmodule
