import ctypes
import time 

# 共有ライブラリを読み込む
lib_write = ctypes.CDLL('./libpcie_write.so')
lib_read = ctypes.CDLL('./libpcie_read.so')

# C関数の引数と戻り値の型を指定する（write）
lib_write.write_to_device.argtypes = (ctypes.c_uint, ctypes.c_ulong)
lib_write.write_to_device.restype = ctypes.c_int

# C関数の引数と戻り値の型を指定する（read）
lib_read.read_from_device.argtypes = (ctypes.POINTER(ctypes.c_uint), ctypes.c_ulong)
lib_read.read_from_device.restype = ctypes.c_int

def write_to_device_python(data, offset):
    """
    Python関数: デバイスに32ビットのデータを書き込む

    :param data: 書き込むデータ（0x00000000 ~ 0xFFFFFFFF）
    :param offset: 書き込むオフセットアドレス
    """
    result = lib_write.write_to_device(ctypes.c_uint(data), ctypes.c_ulong(offset))
    if result != 0:
        raise IOError("Failed to write to device")

def read_from_device_python(offset):
    """
    Python関数: デバイスから32ビットのデータを読み取る

    :param offset: 読み取るオフセットアドレス
    :return: 読み取った32ビットのデータ
    """
    data = ctypes.c_uint(0)  # 読み取り用の変数を用意
    result = lib_read.read_from_device(ctypes.byref(data), ctypes.c_ulong(offset))
    if result != 0:
        raise IOError("Failed to read from device")
    return data.value
    