# PCIe Driver for Raspberry Pi 5

## Overview
This repository contains the PCIe driver and related tools for running **EduGPU** on a **Raspberry Pi 5**.

---

## Folder Structure

| Folder | Description                                       |
|--------|---------------------------------------------------|
| apps   | Test programs                                     |
| common | Common files for the PCIe driver                  |
| pcie   | PCIe driver for Raspberry Pi 5                    |
| utils  | Utility files for the PCIe driver                 |
| vdma   | VDMA files for the PCIe driver (under development)|

---

## Installation

```bash
cd ./pcie
make all
sudo make install_dkms
sudo modprobe EduGPU_pcie_driver

```

## Using of apps folder

### Command-line Input
```bash
# Set control register
./reg_set 01
0x00000001: Program Write
0x00000002: Data Write
0x00000004: DDR Write
0x00000080: GPU Start
0x00000100: GPU Soft Reset
Wrote 4 bytes to /dev/EduGPU_pcie_driver0 at address 0xf800:
Written data: 0x00000001

# Write to a PCIe register
./write_pcie 04 23
Wrote 4 bytes to /dev/EduGPU_pcie_driver0 at address 0x4:
00 00 00 23

# Read from a PCIe register
./read_pcie 04
Read start: Success
Read 4 bytes from /dev/EduGPU_pcie_driver0 at address 0x4:
00 00 00 23
```
