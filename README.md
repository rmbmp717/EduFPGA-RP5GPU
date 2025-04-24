# EduFPGA-RP5GPU (Verilog HDL & C++ & Python)

## Introduction

EduFPGA-RP5GPU is an educational GPU designed to work with the Raspberry Pi 5.
The design runs on an FPGA and includes a PCIe controller.
It communicates with the Raspberry Pi 5 via a PCIe driver.
This project includes a PCIe driver that can be compiled for the Raspberry Pi 5, along with sample Python scripts.

*Note: This project was created for educational and experimental purposes.
Features for actual products and performance improvements are future considerations.*

## Demo Setup

- Demo environment:  
  Raspberry Pi 5 + Tang Mega 138K + PCIe converter board  
![Demo Setup](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/RP5_GPU.jpg?raw=true)

## GPU

This design is inspired by the following tiny GPU project:  
https://github.com/adam-maj/tiny-gpu

## Directories

- GPU design data for FPGA operation  
- PCIe driver code that can be compiled on Raspberry Pi 5  
- Sample Python script to operate the GPU  

## Block Diagram

- System Block Diagram  
![Block Diagram](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/eduFPGA_GPU.jpg?raw=true)

## Deliverables

- GPU design data (Verilog)  
- Demo board design (KiCAD)  
- PCIe driver (C++)  
- PCIe controller for FPGA (Verilog)  
- Python program for character image recognition demo  
- PCIe Write/Read program (C++)  

## Demo Results

- Character image recognition result  
![Recognition Result](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_demo.jpg?raw=true)

## Demo Board

- Although the tang console has been released and will be used going forward,
  a custom FPGA board was previously designed.
- Designed using KiCAD  
- (Note: some wiring corrections are needed)  
![Demo Board](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/FPGA_board.jpg?raw=true)

## Unresolved Issues

- Issue with PCIe IP recognition on Raspberry Pi 5 at boot time  
- DMA transfer is not yet supported  

## Future Plans

- After confirming basic functionality, we consulted with the Sapporo Small Business Center,
  who concluded that the current setup is still "too difficult" to proceed.
- Once the Sipeed FPGA board (tang console) arrives from a Chinese supplier,
  we will flash the current design, confirm operation, and then conclude the project.

## Final Thoughts

- This is a summary of past design notes and project data.
- It's easy to forget things from a year ago unless you document them like this.
