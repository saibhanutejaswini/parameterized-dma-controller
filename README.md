# Parameterized DMA Controller using SystemVerilog

## About the Project
- Designed and implemented a parameterized DMA (Direct Memory Access) controller using SystemVerilog.
- Enables memory-to-memory data transfers without requiring the CPU to manage every individual transfer.
- Developed and simulated using Xilinx Vivado.
- Uses a Finite State Machine (FSM) to control the data transfer process.

## Features
- Parameterized address width, data width, and transfer length.
- FSM-based control logic.
- Automatic source and destination address generation.
- Transfer counter to track remaining words.
- Data buffer for temporarily storing read data.
- Memory read request and response handshaking.
- Memory write request and ready handshaking.
- `busy` signal to indicate an active transfer.
- `done` signal to indicate transfer completion.
- `irq` signal to indicate completion through an interrupt output.
- Support for zero-length transfers.

## Design Parameters
- `ADDR_WIDTH = 32` — Defines the address bus width.
- `DATA_WIDTH = 32` — Defines the data bus width.
- `LEN_WIDTH = 16` — Defines the transfer length width.
- Uses byte-addressed memory.
- Increments source and destination addresses by 4 bytes for each 32-bit word transferred.

## Internal Modules and Logic
- **Control FSM:** Controls the sequence of read, wait, write, and completion states.
- **Address Generator:** Maintains and increments source and destination addresses.
- **Transfer Counter:** Tracks the number of remaining words.
- **Data Buffer:** Stores read data before it is written to the destination.
- **Read Interface:** Requests data from source memory and waits for valid data.
- **Write Interface:** Writes buffered data to destination memory when the memory is ready.
- **Status Logic:** Generates the `busy`, `done`, and `irq` signals.

## Tools and Technologies
- SystemVerilog
- Xilinx Vivado
- Vivado XSim
- RTL Design
- Behavioral Simulation

## Repository Structure
- `dma_controller.sv` — Main DMA controller RTL design.
- `dma_controller_tb.sv` — SystemVerilog testbench for functional verification.
- `README.md` — Project documentation.

## Verification
- Developed a testbench to verify DMA controller functionality.
- Simulated the design using Vivado behavioral simulation.
- Verified a three-word memory-to-memory transfer.
- Checked the correctness of all three destination data words.
- Verified zero-length transfer behavior.
- Confirmed that a zero-length transfer does not write data to the destination.

## Test Results
- **Three-word transfer:** PASS
- **Destination data verification:** PASS
- **Zero-length transfer:** PASS
- **Overall behavioral simulation:** ALL TESTS PASSED

## How to Run
- Open the project in Xilinx Vivado.
- Add `dma_controller.sv` under Design Sources.
- Add `dma_controller_tb.sv` under Simulation Sources.
- Set `dma_controller_tb` as the simulation top module.
- Run Behavioral Simulation.
- Check the simulation console for the test results.

## Future Improvements
- Verify single-word transfers.
- Test delayed memory read responses.
- Test write backpressure conditions.
- Inspect FSM transitions using simulation waveforms.
- Run synthesis and review warnings.
- Explore FPGA implementation and resource utilization.

## Learning Outcomes
- Understanding of DMA controller architecture.
- Practical experience with SystemVerilog RTL design.
- FSM design and state transitions.
- Sequential and combinational logic.
- Memory interface handshaking.
- Address generation and transfer counting.
- Testbench development and functional verification.

## Author
SAI BHANU TEJASWINI
Developed as an educational RTL design project to explore DMA controller architecture and digital hardware design using SystemVerilog.

**Note:** This project uses a simple memory handshake interface and is not a full AXI- or AHB-compliant DMA implementation.
