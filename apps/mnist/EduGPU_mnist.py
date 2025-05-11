import os
# TensorFlowの最適化オプションを無効化
os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"
import sys
import pickle
import random
import numpy as np
from tensorflow.keras.datasets import mnist
import time  # 計算時間を計測するために追加
import matplotlib.pyplot as plt

# 自作FP16ライブラリのインポート
import fp16_lib

# 計算精度の設定
TRAINING_DTYPE = np.float32
PREDICTION_DTYPE = np.float16
PREDICT_MODE = 1  # 0: 学習, 1: 予測
GPU_USE_MODE = 1  # 0: dont use GPU, 1 : GPU use

import GPU_asm5_set

class ReLU:
    def __call__(self, x):
        self.x = x.astype(TRAINING_DTYPE)  # FP32に変換
        return np.maximum(0, x).astype(TRAINING_DTYPE)

    def backward(self, d):
        return (d * (self.x > 0)).astype(TRAINING_DTYPE)

    def update(self, lr):
        pass

class Linear:
    def __init__(self, n_input, n_output, program=None):
        self.w = np.random.randn(n_input, n_output).astype(TRAINING_DTYPE) * np.sqrt(2.0 / n_input)
        self.b = np.zeros(n_output, dtype=TRAINING_DTYPE)
        self.program = program  # Store the program as an instance variable

    def __call__(self, x):
        if PREDICT_MODE == 1:
            # Use FP16 precision in prediction mode
            if GPU_USE_MODE == 1:
                # GPU mode: calculate each dot product using the GPU
                result = np.zeros(self.b.shape, dtype=PREDICTION_DTYPE)
                for i in range(len(x)):
                    # Pass each x[i] and corresponding weight column to GPU
                    weight_column = self.w[i, :]  # Get the i-th weight column
                    gpu_result = GPU_asm5_set.calculate_dot_product(x[i], weight_column, data_addr=0x020)

                    # Convert gpu_result to array and clip values to avoid overflow
                    gpu_result_array = np.array(gpu_result, dtype=PREDICTION_DTYPE)
                    gpu_result_array = np.clip(gpu_result_array, -1, 1)  # Clip 
                    # Add clipped result to the overall result
                    result += gpu_result_array
                
                # Add bias and return
                result += self.b.astype(PREDICTION_DTYPE)
                return result.astype(PREDICTION_DTYPE)
            else:
                self.x = x.astype(PREDICTION_DTYPE)
                return (np.dot(x, self.w) + self.b).astype(PREDICTION_DTYPE)
        else:
            # Use FP32 precision in training mode
            self.x = x.astype(TRAINING_DTYPE)
            return (np.dot(x, self.w) + self.b).astype(TRAINING_DTYPE)

    def backward(self, d):
        d = d.astype(TRAINING_DTYPE)
        self.grad_w = np.outer(self.x, d).astype(TRAINING_DTYPE)
        self.grad_b = d
        return np.dot(d, self.w.T).astype(TRAINING_DTYPE)

    def update(self, lr):
        lr = TRAINING_DTYPE(lr)
        self.w -= lr * self.grad_w
        self.b -= lr * self.grad_b

    def dump_weights(self, file_path):
        with open(file_path, 'w') as f:
            f.write("Weights:\n")
            for row in self.w:
                fp16_hex = [hex(np.frombuffer(val.astype(np.float16).tobytes(), dtype=np.uint16)[0]) for val in row]
                f.write(f"FP16 (hex): {fp16_hex}\n")
            f.write("Biases:\n")
            fp16_hex_b = [hex(np.frombuffer(val.astype(np.float16).tobytes(), dtype=np.uint16)[0]) for val in self.b]
            f.write(f"FP16 (hex): {fp16_hex_b}\n")
        print(f"Weights saved to {file_path}")

    def load_weights(self, file_path):
        with open(file_path, 'r') as f:
            lines = f.readlines()
            weight_lines = [line for line in lines if line.startswith("FP16 (hex):")]
            bias_line = lines[-1]

            weights = []
            for line in weight_lines[:-1]:  # Ignore the last line as it is for biases
                values = line.strip().split(': ')[1].strip('[]').replace("'", "").split(', ')
                values = [float(np.frombuffer(int(val, 16).to_bytes(2, 'little'), dtype=np.float16)[0]) for val in values]
                weights.append(values)
            self.w = np.array(weights, dtype=TRAINING_DTYPE)

            bias_values = bias_line.strip().split(': ')[1].strip('[]').replace("'", "").split(', ')
            bias_values = [float(np.frombuffer(int(val, 16).to_bytes(2, 'little'), dtype=np.float16)[0]) for val in bias_values]
            self.b = np.array(bias_values, dtype=TRAINING_DTYPE)
        print(f"Weights loaded from {file_path}")

        # 保存された重みとバイアスをファイルに出力
        with open(file_path.replace('weights', 'loaded_weights'), 'w') as f:
            f.write("Loaded Weights (FP16 hex):\n")
            for row in self.w:
                fp16_hex = [hex(np.frombuffer(val.astype(np.float16).tobytes(), dtype=np.uint16)[0]) for val in row]
                f.write(f"FP16 (hex): {fp16_hex}\n")
            f.write("Loaded Biases (FP16 hex):\n")
            fp16_hex_b = [hex(np.frombuffer(val.astype(np.float16).tobytes(), dtype=np.uint16)[0]) for val in self.b]
            f.write(f"FP16 (hex): {fp16_hex_b}\n")
        print(f"Loaded weights saved to {file_path.replace('weights', 'loaded_weights')}")

class NeuralNetwork:
    def __init__(self, *layers):
        self.layers = layers

    def __call__(self, x):
        x = x.astype(TRAINING_DTYPE)
        for layer in self.layers:
            x = layer(x)
        return x

    def call_float16(self, x):
        x = x.astype(PREDICTION_DTYPE)
        for layer in self.layers:
            if isinstance(layer, Linear):
                layer.w = layer.w.astype(PREDICTION_DTYPE)
                layer.b = layer.b.astype(PREDICTION_DTYPE)
            x = layer(x).astype(PREDICTION_DTYPE)
        return x

    def backward(self, d):
        d = d.astype(TRAINING_DTYPE)
        for layer in self.layers[::-1]:
            d = layer.backward(d)

    def update(self, lr):
        for layer in self.layers:
            layer.update(lr)

    def dump_weights(self):
        for i, layer in enumerate(self.layers):
            if isinstance(layer, Linear):
                layer.dump_weights(f'layer_{i}_weights.txt')

    def load_weights(self):
        for i, layer in enumerate(self.layers):
            if isinstance(layer, Linear):
                layer.load_weights(f'layer_{i}_weights.txt')

class CrossEntropy:
    def __call__(self, y, t):
        y = self._softmax(y).astype(TRAINING_DTYPE)
        self.y = y
        self.t = t.astype(TRAINING_DTYPE)
        loss = -np.sum(t * np.log(np.clip(y, 1e-15, 1))).astype(TRAINING_DTYPE)  # 安定性のためのクリッピング
        return loss

    def backward(self):
        return (self.y - self.t).astype(TRAINING_DTYPE)

    def _softmax(self, y):
        y = y - np.max(y).astype(TRAINING_DTYPE)  # 安定性向上のため最大値を引く
        exp_y = np.exp(y).astype(TRAINING_DTYPE)
        return (exp_y / np.sum(exp_y)).astype(TRAINING_DTYPE)

# MNISTデータセットの読み込み
(x_train, y_train), (x_test, y_test) = mnist.load_data()

# データの正規化と平坦化
x_train = (x_train.reshape(-1, 784) / 255).astype(TRAINING_DTYPE)
x_test = (x_test.reshape(-1, 784) / 255).astype(TRAINING_DTYPE)

# one-hotエンコーディング
y_train = np.eye(10, dtype=TRAINING_DTYPE)[y_train]
y_test = np.eye(10, dtype=TRAINING_DTYPE)[y_test]

# モデルの定義
neural_net1 = NeuralNetwork(
    Linear(784, 64, program=GPU_asm5_set.program),
    ReLU(),
    Linear(64, 32, program=GPU_asm5_set.program),
    ReLU(),
    Linear(32, 10, program=GPU_asm5_set.program)
)

if PREDICT_MODE == 0:
    # モデルのトレーニング
    def train(model, x, y, criterion, lr, n_epochs, print_interval=1000):
        lr = TRAINING_DTYPE(lr)
        for epoch in range(1, n_epochs + 1):
            start_time = time.time()
            loss = TRAINING_DTYPE(0)
            for i in range(len(x)):
                idx = np.random.randint(0, len(x))
                sample_x = x[idx]
                sample_y = y[idx]

                out = model(sample_x)
                loss += criterion(out, sample_y)
                d = criterion.backward()
                model.backward(d)
                model.update(lr)

                if (i + 1) % print_interval == 0:
                    print(f'Epoch {epoch}, Sample {i + 1}/{len(x)}, Current Loss: {loss / (i + 1):.4f}')

            elapsed_time = time.time() - start_time
            print(f'Epoch {epoch} completed. Average loss: {loss / len(x):.4f}, Time taken: {elapsed_time:.2f} seconds')

    train(neural_net1, x_train, y_train, CrossEntropy(), 0.0001, 5, print_interval=1000)
    # 重みの保存
    neural_net1.dump_weights()

elif PREDICT_MODE == 1:
    # 重みの読み込み
    neural_net1.load_weights()
    # GPU mode
    if GPU_USE_MODE == 1:
        # Transfer the GPU program to the device
        GPU_asm5_set.transfer_program_to_gpu(GPU_asm5_set.program)


# 結果の可視化

fig, axes = plt.subplots(4, 10, figsize=(20, 8))  # 4行10列のサブプロットを作成
axes = axes.ravel()  # 2次元のaxesを1次元にフラット化
for i in range(40):
    image_number = random.randrange(1000)
    print("===========================")
    print(f"image number = {image_number}")
    sample_x = x_test[image_number]
    sample_y = y_test[image_number]
    t = np.argmax(sample_y)
    
    start_time = time.time()  # 計算開始時間
    pred = np.argmax(neural_net1.call_float16(sample_x))
    end_time = time.time()  # 計算終了時間
    
    elapsed_time = end_time - start_time  # 経過時間を計算
    print(f'Prediction time for sample {i}: {elapsed_time:.6f} seconds')

    axes[i].imshow(sample_x.reshape(28, 28), cmap='gray')
    axes[i].set_title(f'True: {t} Pred: {pred}')
    axes[i].axis('off')

'''
# 結果の可視化（1枚のみ表示）
fig, ax = plt.subplots(figsize=(5, 5))  # 1枚のサブプロットを作成

sample_x = x_test[13]  # 最初のテストサンプル
sample_y = y_test[13]
t = np.argmax(sample_y)

start_time = time.time()  # 計算開始時間
pred = np.argmax(neural_net1.call_float16(sample_x))
end_time = time.time()  # 計算終了時間

elapsed_time = end_time - start_time  # 経過時間を計算
#print(f'Prediction time for sample: {elapsed_time:.6f} seconds')

ax.imshow(sample_x.reshape(28, 28), cmap='gray')
ax.set_title(f'True: {t} Pred: {pred}')
ax.axis('off')
'''
'''
fig, axes = plt.subplots(1, 8, figsize=(20, 5))  # 1行8列のサブプロットを作成

# 8枚のサンプルを表示
for i in range(8):
    print("===========================")
    print(f"image number = {i}")
    sample_x = x_test[i]  # i番目のテストサンプル
    sample_y = y_test[i]
    t = np.argmax(sample_y)

    start_time = time.time()  # 計算開始時間
    pred = np.argmax(neural_net1.call_float16(sample_x))
    end_time = time.time()  # 計算終了時間

    elapsed_time = end_time - start_time  # 経過時間を計算
    print(f'Prediction time for sample {i}: {elapsed_time:.6f} seconds')

    # 各サブプロットに画像とタイトルを設定
    axes[i].imshow(sample_x.reshape(28, 28), cmap='gray')
    axes[i].set_title(f'True: {t} Pred: {pred}')
    axes[i].axis('off')
'''
plt.tight_layout()
plt.show()
