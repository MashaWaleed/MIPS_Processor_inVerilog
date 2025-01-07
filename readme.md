# MIPS Processor Implementation in Verilog 🚀

A fully functional MIPS processor implementation in Verilog HDL, featuring a 5-stage pipeline architecture with support for basic MIPS instructions including arithmetic, memory operations, and branching.

## 🎯 Features

- **Complete MIPS Architecture Implementation**

  - 32-bit datapath
  - Harvard architecture (separate instruction and data memory)
  - 5-stage pipeline
  - Register file with 32 general-purpose registers
  - ALU supporting multiple operations

- **Supported Instructions**
  - Arithmetic: ADD, SUB
  - Logical: AND, OR
  - Memory: LW (Load Word), SW (Store Word)
  - Branching: BEQ (Branch if Equal)
  - Comparison: SLT (Set Less Than)

## 🏗️ Architecture Overview

The processor implements a classic MIPS architecture with the following key components:

![](mips-datapath-diagram)

### Core Components

1. **Program Counter (PC)**

   - 32-bit counter
   - Increments by 4 each cycle
   - Supports branch operations

2. **Instruction Memory**

   - 256 x 32-bit memory
   - Read-only during execution
   - Contains program instructions

3. **Register File**

   - 32 x 32-bit registers
   - Dual read ports
   - Single write port
   - Zero register ($0) hardwired to 0

4. **ALU (Arithmetic Logic Unit)**

   - Supports operations:
     - AND, OR (Logical)
     - ADD, SUB (Arithmetic)
     - SLT (Comparison)
   - Generates zero flag for branch operations

5. **Data Memory**

   - 256 x 32-bit memory
   - Supports word-aligned access
   - Read/Write capability

6. **Control Unit**
   - Generates control signals based on instruction opcode
   - Manages datapath routing
   - Controls ALU operation

## 🛠️ Implementation Details

### Key Modules

```verilog
module mips_processor (
    input clk, reset,
    output [31:0] pc_out,
    output [31:0] instruction_out,
    output [31:0] alu_result_out
);
```

The processor is implemented in a modular fashion with the following key components:

- `alu_unit`: Arithmetic and logic operations
- `control_decoder`: Instruction decoding and control signal generation
- `instruction_memory`: Program storage
- `data_memory`: Data storage
- `register_file`: Register bank
- Various multiplexers and adders for data routing

## 🧪 Testing

The implementation includes a comprehensive testbench (`mips_processor_tb`) that:

- Initializes the processor
- Executes a test program
- Monitors key signals and memory contents
- Generates VCD file for waveform analysis

### Sample Test Program

```
memory[0] = 32'h00221820;  // ADD $3, $1, $2
memory[1] = 32'h00612022;  // SUB $4, $3, $1
memory[2] = 32'hAC040004;  // SW $4, 4($0)
memory[3] = 32'h8C050004;  // LW $5, 4($0)
memory[4] = 32'h10850004;  // BEQ $4, $5, 4
```

## 🚀 Getting Started

1. **Prerequisites**

   - Verilog HDL simulator (e.g., Icarus Verilog)
   - Waveform viewer (e.g., GTKWave)

2. **Compilation**

   ```bash
   iverilog -o mips_processor mips_processor.v
   ```

3. **Simulation**

   ```bash
   vvp mips_processor
   ```

4. **Waveform Analysis**
   ```bash
   gtkwave mips_processor_debug.vcd
   ```

## 📈 Performance Monitoring

The testbench includes comprehensive monitoring of:

- Program Counter
- Current Instruction
- ALU Results
- Register Contents
- Memory Contents

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest enhancements
- Add new features
- Improve documentation

## 📝 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- Based on the MIPS architecture developed by MIPS Technologies
- Inspired by various open-source MIPS implementations
