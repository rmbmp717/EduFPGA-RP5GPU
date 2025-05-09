import ctypes

# 共有ライブラリを読み込む
lib = ctypes.CDLL('./libexample.so')

# C関数の引数と戻り値の型を指定する
lib.add.argtypes = (ctypes.c_int, ctypes.c_int)
lib.add.restype = ctypes.c_int

# 関数を呼び出す
result = lib.add(10, 20)
print(result)  # 出力: 30