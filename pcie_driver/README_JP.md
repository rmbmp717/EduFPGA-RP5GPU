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

TBD
