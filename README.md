# EduFPGA-RP5GPU (Verilog HDL & C++ & Python)

## Introduction

EduFPGA-RP5GPU is an educational GPU designed to operate in conjunction with the Raspberry Pi 5.  
The design data runs on the FPGA and includes a PCIe controller.  
It can communicate with the Raspberry Pi 5 through a PCIe driver.  
The project includes a PCIe driver that can be compiled on the Raspberry Pi 5 and sample Python scripts.

*Note: This project is created for educational and experimental purposes. Functions for actual product use and performance enhancements will be considered in the future.*

## Demo Environment
- Demo Environment
- Raspberry Pi 5 + Tang Mega 138K + PCIe conversion board <br>

![Demo Environment](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/RP5_GPU.jpg?raw=true)

## GPU
- Designed with reference to the following tiny-gpu project:  
https://github.com/adam-maj/tiny-gpu
- The ISA has been extended by adding floating-point multiplication instructions.
- GPU ISA <br>

![GPU ISA](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_ISA.jpg?raw=true)

## Directories
- Design data for the GPU that operates on FPGA.
- Design data for the PCIe controller that operates on FPGA.
- PCIe driver code that can be compiled on the Raspberry Pi 5.
- Sample Python script to operate the GPU.

## Block Diagram
- Overall Block Diagram <br>

![Overall Block Diagram](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/eduFPGA_GPU.jpg?raw=true)

## Completed Deliverables
- GPU design data (Verilog)
- Memory controller for GPU data (Verilog)
- Demo board design (KiCAD)
- PCIe driver (C++)
- FPGA-side PCIe controller (Verilog)
- Python program for character image recognition demo
- PCIe Write/Read program (C++)

## Demo Results
- Executed character recognition code on the Raspberry Pi 5.
- Data was transferred to the GPU via PCIe, and deep learning computation was executed.
- Character Image Recognition Result <br>

![Character Image Recognition Result](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_demo.jpg?raw=true)

## Demo Board
- Although the plan to use this demo board was discontinued after the release of the Tang Console, a board capable of mounting an FPGA sub-board was designed.
- Designed using KiCAD.
- (There are wiring correction points that need to be fixed.)

![Demo Board](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/FPGA_board.jpg?raw=true)

## Unresolved Issues
- PCIe IP recognition issue at Raspberry Pi 5 boot.
- DMA transfer is not yet supported.
- The design has not been developed to the point of using DDR memory on the FPGA board concurrently with the GPU.

## Future Plans
- After completing minimum operation confirmation, I consulted with representatives at the Sapporo Small Business Center and concluded that "it would be difficult to commercialize" (although I had explained from the beginning that it was for educational purposes).
- Once the Sipeed FPGA board (Tang Console) arrives from a Chinese supplier, I will write the current design data to it, verify operation, and then conclude the project.

## Personal Reflection
- I have compiled past Note articles and design data.
- The total design period was about two and a half months.
- If I don't summarize things from a year ago, I tend to forget them.
