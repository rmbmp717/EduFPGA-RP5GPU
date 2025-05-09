import pcie_rwlib

# 書き込みテスト
#pcie_rwlib.write_to_device_python(0x123456FF, 0x0020)  # 32ビットデータ(0x12345678)を0x0004アドレスに書き込む
pcie_rwlib.write_to_device_python(0x00000001, 0x0020)  # 32ビットデータ(0x12345678)を0x0004アドレスに書き込む

# 読み取りテスト
read_data = pcie_rwlib.read_from_device_python(0x0020)  # 0x0008アドレスから32ビットデータを読み取る
print(f"Data read from device at 0xTBD: 0x{read_data:08X}")