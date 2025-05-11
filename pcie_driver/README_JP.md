# 内容：Raspberry5向けPCIEドライバ

## フォルダ構成

| フォルダ名　　　　　　　| 内容                                  |
|------------|--------------------------------------|
| apps       | 動作確認用プログラム                     | 
| common     | PCIEドライバcommonファイル                | 
| pcie       | Raspberry5向けPCIEドライバ                |
| utils       |  PCIEドライバutilsファイル                |
| vdma       |  PCIEドライバvdmaファイル（設計中）          |

## 使用法


### Command-line Input
```bash
$ cd ./pcie
$ make all
$ sudo make install_dkms
$ sudo modprobe EduGPU_pcie_driver

```

### appsフォルダの使用法
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
