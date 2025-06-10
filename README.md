# EduFPGA-RP5GPU (Verilog HDL & C++ & Python)

## Introduction

EduFPGA-RP5GPU is an educational GPU designed to work with the Raspberry Pi 5.  
The design data runs on the FPGA and includes a PCIe controller.  
Communication with the Raspberry Pi 5 is possible via a PCIe driver.  
The project includes a PCIe driver compatible with the Raspberry Pi 5 and sample Python scripts.

*Note: This project was created for educational and experimental purposes. Product-grade features and performance improvements will be considered in the future.*

## Demo Environment
- Demo setup
- Raspberry Pi 5 + Tang Mega 138K + PCIe adapter board + ASM1182e PCIe repeater board <br>

![Demo setup](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/RP5_console_GPU.jpg?raw=true)

- ASM1182e PCIe repeater board
- Without using the ASM1182e PCIe repeater board, the Gowin FPGA's PCIe IP is not recognized at RP5 startup.<br>
![PCIe repeater board](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/ASM1182e.jpg?raw=true)

## GPU
- The design is based on the tiny-gpu project by the following author:
https://github.com/adam-maj/tiny-gpu
- The ISA (instruction set architecture) has been extended to include a floating-point multiplication instruction.
- GPU ISA <br>

![GPU ISA](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_ISA.jpg?raw=true)

## Directories
- GPU design data runnable on FPGA.
- Includes PCIe controller design data runnable on FPGA.
- PCIe driver code compilable on Raspberry Pi 5.
- Sample Python script to operate the GPU.

## Block Diagram
- Overall block diagram <br>

![Overall block diagram](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/eduFPGA_GPU.jpg?raw=true)

## Delivered Artifacts
- GPU design data (Verilog)
- GPU data memory controller (Verilog)
- Demo board design (KiCAD)
- PCIe driver (C++)
- FPGA-side PCIe controller (Verilog)
- Python program for character image recognition demo
- PCIe Write/Read program (C++)

## Demo Results
- Ran character recognition code on the Raspberry Pi 5.
- Data is transferred to the GPU via PCIe, and DL operations are executed.
- Character image recognition result when running EduGPU_mnist.py <br>

![Character image recognition result](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_demo.jpg?raw=true)

## PCIe IP Settings
- The PCIe IP BAR settings are as follows: <br>

| BAR  | Enabled | Type    | 64 bit | Prefetchable | Size         | Value (Hex) |
|------|---------|---------|--------|--------------|--------------|-------------|
| Bar0 | Yes     | Memory  | Yes    | No           | 1 Kilobyte   | FFFFFC00    |
| Bar2 | Yes     | Memory  | Yes    | No           | 64 Kilobytes | FFFF0000    |
| Bar4 | Yes     | Memory  | Yes    | No           | 2 Kilobytes  | FFFFF800    |

## Demo Board
- Although the tang console has now been released and I no longer plan to use this, I designed a board that can accommodate FPGA sub-boards.
- Designed with KiCAD.
- Compatible with the Tang 138K SOM board.
- (There are wiring correction points)

![Demo board](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/FPGA_board.jpg?raw=true)

## Unresolved Issues
- DMA transfer is not yet supported.
- The design has not progressed to the point of using the DDR memory on the FPGA board concurrently with the GPU.

## Future Plans
- After completing minimal operation checks, I consulted with someone at the Sapporo Small and Medium Enterprise Center, and the conclusion was that "it would be difficult to commercialize" (I had explained from the start that this was for educational purposes).
- Once the Sipeed FPGA board (tang console) arrives from a Chinese online store as a replacement for the demo board, I plan to write the existing design data to it, confirm operation, and then wrap up the project.

## Impressions
- I have compiled the past Notes and design data.
- The design period was 2.5 months.
- If you don’t organize things from a year ago, you tend to forget them.
