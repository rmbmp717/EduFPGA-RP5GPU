# EduFPGA-RP5GPU (Verilog HDL & C++ & Python)

## Introduction

EduFPGA-RP5GPU is an educational GPU that operates in conjunction with a Raspberry Pi 5. The design runs on an FPGA and includes a PCIe controller. Communication with the Raspberry Pi 5 is handled via a PCIe driver. The project includes a PCIe driver that can be built on the Pi 5 and sample Python scripts to drive the GPU.

> **Note:** This project was created for educational and experimental purposes. Production-grade features and performance optimizations are subjects for future consideration.

## Demo Environment
- Hardware setup:
  Raspberry Pi 5 + Tang Mega 138K + PCIe adapter board  
  ![Demo setup](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/RP5_GPU.jpg?raw=true)

## GPU
- Designed with reference to Adam Maj’s [tiny-gpu](https://github.com/adam-maj/tiny-gpu).  
- The ISA has been extended to include a floating-point multiply instruction.  
- **GPU ISA**  
  ![GPU ISA](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_ISA.jpg?raw=true)

## Directories
- Verilog source for the FPGA-runnable GPU design  
- Verilog source for the FPGA-side PCIe controller  
- C++ source for the PCIe driver (builds on Raspberry Pi 5)  
- Sample Python scripts to drive the GPU

## Block Diagram
- Overall system block diagram:  
  ![Block diagram](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/eduFPGA_GPU.jpg?raw=true)

## Completed Deliverables
- Verilog GPU design files  
- Demo board schematics (KiCad)  
- PCIe driver (C++)  
- FPGA-side PCIe controller (Verilog)  
- Python character-recognition demo program  
- PCIe write/read test programs (C++)

## Demo Results
- Ran a character-recognition program on the Raspberry Pi 5.  
- Transferred data to the GPU over PCIe and executed deep-learning inference.  
- **Character-recognition output:**  
  ![Recognition result](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_demo.jpg?raw=true)

## Demo Board
- Although Sipeed’s “tang console” is now available (making our custom sub-board less necessary), we designed an FPGA daughter board in KiCad to fit under that form factor.  
- **Status:** Some wiring modifications are still required.  
  ![Demo board](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/FPGA_board.jpg?raw=true)

## Unresolved Issues
- FPGA PCIe IP is not always recognized at Raspberry Pi 5 boot.  
- DMA transfers are not yet supported.

## Future Plans
- After verifying minimal functionality, we consulted with the Sapporo Small & Medium Enterprise Support Center. Their feedback: “As is, commercializing this will be difficult.” (We noted from the start that this is for educational use.)  
- Once the tang console board arrives from China, we will program it with our design, verify operation, and then conclude the project.

## Reflections
- I’ve consolidated my notes and design data here.  
- Design period: two and a half months.  
- It’s easy to forget details from a year ago, so keeping this record was important.
