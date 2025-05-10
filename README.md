# EduFPGA-RP5GPU (Verilog HDL & C++ & Python)

## Introduction

EduFPGA-RP5GPU is an educational GPU designed to work in conjunction with the Raspberry Pi 5.  
The design data runs on the FPGA and includes a PCIe controller.  
Communication with the Raspberry Pi 5 is possible via a PCIe driver.  
The project includes a PCIe driver compatible with the Raspberry Pi 5 and sample Python scripts.

*Note: This project was created for educational and experimental purposes. Product-grade features and performance improvements will be considered in the future.*

## Demo Environment
- Demo setup
- Raspberry Pi 5 + Tang Mega 138K + PCIe adapter board + ASM1182e PCIe repeater board <br>

![Demo setup](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/RP5_GPU_ASM1182e.jpg?raw=true)

- ASM1182e PCIe repeater board
- Without using the ASM1182e PCIe repeater board, the Gowin FPGA's PCIe IP is not recognized at RP5 startup.<br>
![PCIe repeater board](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/ASM1182e.jpg?raw=true)

## GPU
- The design is based on the following tiny-gpu project:
https://github.com/adam-maj/tiny-gpu
- The ISA (instruction set architecture) has been extended with a floating-point multiplication instruction.
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
- Character image recognition result <br>

![Character image recognition result](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_demo.jpg?raw=true)

## Demo Board
- Although the tang console has now been released and I no longer plan to use this, I designed a board that can accommodate FPGA sub-boards.
- Designed with KiCAD.
- (There are wiring correction points)

![Demo board](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/FPGA_board.jpg?raw=true)

## Unresolved Issues
- DMA transfer is not yet supported.
- The design has not progressed to the point of using the DDR memory on the FPGA board
