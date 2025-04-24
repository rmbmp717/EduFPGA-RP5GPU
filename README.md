# EduFPGA-RP5GPU (Verilog HDL & C++ & Python)

## Introduction

EduFPGA-RP5GPU is an educational GPU designed to work with the Raspberry Pi 5.
The design runs on an FPGA and includes a PCIe controller.
It communicates with the Raspberry Pi 5 via a PCIe driver.
This project includes a PCIe driver that can be compiled for the Raspberry Pi 5, along with sample Python scripts.

Note: This project is intended for educational and experimental purposes.
Features for real-world applications and performance improvements are future considerations.

## GPU

The design is based on the "tiny-gpu" project by the following author:
https://github.com/adam-maj/tiny-gpu

## Directories

- GPU design data that runs on the FPGA.
- PCIe driver code that can be compiled on the Raspberry Pi 5.
- Sample Python script to operate the GPU.

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
![Demo Result](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_demo.jpg?raw=true)

## Demo Board

- Although the tang console is now available and will be used going forward,
  a custom FPGA board was previously designed.
- Designed using KiCAD.
- (Note: some wiring needs to be fixed.)
![Demo Board](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/FPGA_board.jpg?raw=true)

## Unresolved Issues

- PCIe IP recognition issue at Raspberry Pi 5 startup
- DMA transfer not yet supported

## Future Plans

- After confirming minimum operation, we consulted with staff at the Sapporo Small Business Center,
  who mentioned that it's still "too difficult" in its current form.
- Once the Sipeed FPGA board (tang console) arrives from China,
  we plan to flash the current design onto it and complete the project after testing.

## Notes

- This is a summary of past design work and documentation.
- It's easy to forget things after a year if you don't write them down.
