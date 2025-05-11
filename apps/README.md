# Contents: DEMO script for GPU operation

## Folder Structure

| Folder Name | Description                                       |
|-------------|---------------------------------------------------|
| GPU_test    | GPU operation test scripts, mainly memory W/R     |
| RW_app      | Memory R/W test scripts                           |
| asm         | Assembler code for GPU operation                  |
| mnist       | Character recognition scripts (MNIST test)        |

## How to run the DEMO script

# Creating neuron weight data
- Set the following in `EduGPU_mnist.py`:

```python
PREDICT_MODE = 0  # 0: training, 1: inference
GPU_USE_MODE = 1  # 1: don't use GPU, 1: use GPU

```

# Run the script:
```bash
$ python EduGPU_mnist.py
```

# Creating assembler code

```bash
$ cd ./asm
$ python EduGPU_Assembler.py assm5.asm
```

# Running the DEMO script

```bash
$ cd ..
$ python EduGPU_mnist.py
```
