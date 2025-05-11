
# Contents: PCIe Driver for Raspberry Pi 5

## Folder Structure

| Folder Name | Description                                 |
|-------------|---------------------------------------------|
| apps        | Test programs                               |
| common      | Common PCIE driver files                    |
| pcie        | PCIE driver for Raspberry Pi 5              |
| utils       | PCIE driver utility files                   |
| vdma        | PCIE driver VDMA files (under development)  |

## Install

### Command-line Input
```bash
$ cd ./pcie
$ make all
$ sudo make install_dkms
$ sudo modprobe EduGPU_pcie_driver
```

## Usage of apps folder

### Command-line Input
```bash
$ ./reg_set 01
0x00000001: Program Write
0x00000002: Data Write
0x00000004: DDR Write
0x00000080: GPU Start
0x00000100: GPU Soft Reset
Wrote 4 bytes to /dev/EduGPU_pcie_driver0 at address 0xf800:
Written data: 0x00000001

$ ./write_pcie 04 23
Wrote 4 bytes to /dev/EduGPU_pcie_driver0 at address 0x4:
00 00 00 23

$ ./read_pcie 04
Read start: Success
Read 4 bytes from /dev/EduGPU_pcie_driver0 at address 0x4:
00 00 00 23
```
