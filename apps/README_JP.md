# 内容：GPUを動作させるためのDEMOスクリプト

## フォルダ構成

| フォルダ名　　　　　　　| 内容                                  |
|------------|--------------------------------------|
| GPU_test   | GPUの動作テストスクリプト。主にメモリW/R   | 
| RW_app     | メモリのR/Wのテストスクリプト            | 
| asm        | GPU動作用アセンブラコード               |
| mnist      | 文字認識実行用スクリプト（mnistテスト）   | 

## DEMOスクリプトの実行方法

# ニューロンの重みデータの作成
- EduGPU_mnist.py で下記のように設定
  
```python
PREDICT_MODE = 0  # 0: 学習, 1: 予測
GPU_USE_MODE = 0  # 0: dont use GPU, 1 : GPU use

```

- スクリプトの実行
```bash
$ python EduGPU_mnist.py

```

# アセンブラコードの作成

```bash
$ cd ./asm
$ python EduGPU_Assembler.py assm5.asm

```

# DEMOスクリプトの実行

- EduGPU_mnist.py で下記のように設定
  
```python
PREDICT_MODE = 1  # 0: 学習, 1: 予測
GPU_USE_MODE = 1  # 0: dont use GPU, 1 : GPU use

```

```bash
$ cd ..
$ python EduGPU_mnist.py

```
