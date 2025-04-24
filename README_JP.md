# EduFPGA-RP5GPU (Verilog HDL & C++ & Python)

## Introduction

EduFPGA-RP5GPU はラズベリーパイ5と接続して動作するGPUです。設計データはFPGA上で動作し、PCIEドライバーを通してラズベリーパイ5と通信可能です。プロジェクトにはPCIEドライバーとサンプルPythonスクリプトを含んでいます。

※なお、本プロジェクトは教育・実験目的で作成されています。実際の製品向け機能や高速化は今後の検討課題となります。

## Directories
- FPGAで動作可能なGPUの設計データです。
- ラズパイ5でコンパイル可能なPCIEのドライバーコードです。
- GPUを動作させるサンプルPythonスクリプトです。

## Block図
全体ブロック図
![サンプル画像](https://github.com/rmbmp717/EduFPGA-RP5GPU/blob/main/image/eduFPGA_GPU.jpg?raw=true)

## 設計済み成果物
- GPUの設計データ（Verilog）
- デモボード設計（KiCAD）
- PCIEドライバー（C++）
- FPGA側PCIEコントローラー（Verilog）
- 文字画像認識デモ用Pythonプログラム
- PCIE Write/Readプログラム（C++）

## デモ動作結果

## 未解決の課題

## 今後の予定

## 所感
