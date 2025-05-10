
# Contents: PCIe Driver for Raspberry Pi 5

## Folder Structure

| Folder Name | Description                                 |
|-------------|---------------------------------------------|
| apps        | Test programs                               |
| common      | Common PCIE driver files                    |
| pcie        | PCIE driver for Raspberry Pi 5              |
| utils       | PCIE driver utility files                   |
| vdma        | PCIE driver VDMA files (under development)  |

## Usage

### Command-line Input
```bash
$ make all
$ sudo make install_dkms
$ sudo modprobe EduGPU_pcie_driver
