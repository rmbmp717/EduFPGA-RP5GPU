# EduFPGA-RP5GPU (Verilog HDL & C++ & Python)

## Introduction

EduFPGA-RP5GPU はラズベリーパイ5と接続して動作する学習教育用GPUです。
設計データはFPGA上で動作し、PCIEコントローラーを含んでいます。
PCIEドライバーを通してラズベリーパイ5と通信可能です。
プロジェクトにはラズパイ5で動作可能なPCIEドライバーとサンプルPythonスクリプトを含んでいます。

※なお、本プロジェクトは教育・実験目的で作成されています。実際の製品向け機能や高速化は今後の検討課題となります。

## デモ動作環境
- デモ動作環境
- raspberry pi 5 + Tang Mega 138K + PCIE変換基板 + ASM1182e PCIEレピーター基板 <br>

![デモ動作環境](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/RP5_GPU_ASM1182e.jpg?raw=true)

- ASM1182e PCIEレピーター基板
- ASM1182e PCIEレピーター基板を使用しないとGowin FPGAのPCIE IPがRP5起動時に認識しません。<br>
![PCIEレピーター基板](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/ASM1182e.jpg?raw=true)

## GPU
- この方のtiny-gpuを参考に設計しています。
https://github.com/adam-maj/tiny-gpu
- ISAは下図の通り、浮動小数点乗算命令を追加しました。
- GPU ISA <br>

![GPU ISA](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_ISA.jpg?raw=true)

## Directories
- FPGAで動作可能なGPUの設計データです。
- FPGAで動作可能なPCIEコントローラーの設計データを含んでいます。
- ラズパイ5でコンパイル可能なPCIEのドライバーコードです。
- GPUを動作させるサンプルPythonスクリプトです。

## Block図
- 全体ブロック図 <br>

![全体ブロック図](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/eduFPGA_GPU.jpg?raw=true)

## 設計済み成果物
- GPUの設計データ（Verilog）
- GPUデータ用メモリコントローラー（Verilog）
- デモボード設計（KiCAD）
- PCIEドライバー（C++）
- FPGA側PCIEコントローラー（Verilog）
- 文字画像認識デモ用Pythonプログラム
- PCIE Write/Readプログラム（C++）

## デモ動作結果
- ラズパイ5上で文字認識コードを実行しました。
- GPUにPCIE経由でデータを転送しDLの演算を実行させています。
- EduGPU_mnist.pyを実行した場合の文字画像認識結果 <br>

![文字画像認識結果](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/GPU_demo.jpg?raw=true)

## PCIE IP設定
- PCIE IPのBAR設定は下記 <br>

| BAR  | Enabled | Type    | 64 bit | Prefetchable | Size        | Value (Hex) |
|------|---------|---------|--------|--------------|-------------|-------------|
| Bar0 | Yes     | Memory  | Yes    | No           | 1 Kilobyte  | FFFFFC00    |
| Bar2 | Yes     | Memory  | Yes    | No           | 64 Kilobytes| FFFF0000    |
| Bar4 | Yes     | Memory  | Yes    | No           | 2 Kilobytes | FFFFF800    |

## デモボード
- tang consoleが発売されたので、今後の使用予定は無くなったのですが、FPGAサブ基板を搭載可能な基板を設計しました。
- tang 138k SOMボードに対応しています。
- kiCADで設計しています。
- （配線要修正箇所があります）

![デモボード](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/FPGA_board.jpg?raw=true)

## 未解決の課題
- DMA転送には未対応の課題。
- FPGAボード上のDDRメモリをGPUと同時に使用するまでは設計を作り込んでいない。

## 今後の予定
- 最小限動作確認の完成後に、札幌中小企業センターの方と相談した結果、このままでは「ビジネス的には難しい」ということです。（最初から教育向けと説明しましたが）
- デモボードの代わりとなるSipeedのFPGAボード（tang console）が中国通販から届き次第、今までの設計データを書き込んで、動作確認した後にプロジェクト終了とします。

## 所感
- 過去Noteと設計データをまとめてみました。
- 設計期間は2ヶ月半でした。
- 1年前の事をまとめておかないと忘れてしまいますしね。
