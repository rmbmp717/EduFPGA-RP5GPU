import pcie_rwlib
import time
import struct

from asm import assm4_code
from asm import assm4_data

program = [(instruction, idx * 0x04) for idx, instruction in enumerate(assm4_code.program)]
data = [(value, idx * 0x04) for idx, value in enumerate(assm4_data.data)]

REGADDR = 0xF800
THREADADDR = 0xF400

def float_to_fp16(value):
    # Convert to 32-bit float representation
    packed = struct.pack('>f', value)
    int_rep = struct.unpack('>I', packed)[0]

    # Extract sign, exponent, and mantissa
    sign = (int_rep >> 31) & 0x1
    exp = (int_rep >> 23) & 0xFF
    mantissa = int_rep & 0x7FFFFF

    # Convert to 16-bit floating point
    if exp == 0:  # Zero or subnormal
        exp_fp16 = 0
        mantissa_fp16 = 0
    elif exp == 0xFF:  # Inf or NaN
        exp_fp16 = 0x1F
        mantissa_fp16 = (mantissa != 0) * 0x200  # NaN has a non-zero mantissa
    else:
        exp_fp16 = max(0, min(0x1F, exp - 127 + 15))
        mantissa_fp16 = mantissa >> 13

    # Assemble 16-bit result
    fp16 = (sign << 15) | (exp_fp16 << 10) | mantissa_fp16
    return fp16

def fp16_to_float(fp16):
    # Extract sign, exponent, and mantissa from 16-bit representation
    sign = (fp16 >> 15) & 0x1
    exp = (fp16 >> 10) & 0x1F
    mantissa = fp16 & 0x3FF

    if exp == 0:  # Zero or subnormal
        if mantissa == 0:
            return (-1)**sign * 0.0
        else:
            return (-1)**sign * (mantissa / 2**10) * 2**(-14)
    elif exp == 0x1F:  # Inf or NaN
        if mantissa == 0:
            return float('inf') if sign == 0 else float('-inf')
        else:
            return float('nan')
    else:
        return (-1)**sign * (1 + mantissa / 2**10) * 2**(exp - 15)

# プログラムメモリに書き込む
print("\nWrite Program memory")
pcie_rwlib.write_to_device_python(0x01, REGADDR)  # Register set
read_data = pcie_rwlib.read_from_device_python(REGADDR)

# Write each instruction from the program list
for instruction, address in program:
    pcie_rwlib.write_to_device_python(instruction, address)
    print(f"Written instruction {bin(instruction)} to address {hex(address)}")

print("\nProgram Data check")
for _, address in program:
    read_data = pcie_rwlib.read_from_device_python(address)
    print(f"Read data from address {hex(address)}: {bin(read_data)}")

# データメモリに書き込む
print("\nWrite Data memory")
pcie_rwlib.write_to_device_python(0x02, REGADDR)  # Register set
read_data = pcie_rwlib.read_from_device_python(REGADDR)

# Write each data entry from the data list
for value, address in data:
    pcie_rwlib.write_to_device_python(value, address)
    print(f"Written data {hex(value)} to address {hex(address)}")

print("\nData Memory Data check")
for _, address in data:
    read_data = pcie_rwlib.read_from_device_python(address)
    print(f"Read data from address {address}: {read_data}")

print("\nThread num set")
pcie_rwlib.write_to_device_python(0x08, THREADADDR)  # Register set
read_data = pcie_rwlib.read_from_device_python(THREADADDR)
time.sleep(0.1)

# GPU start
print("\nGPU run")
pcie_rwlib.write_to_device_python(0x00, REGADDR)  # Register set
pcie_rwlib.write_to_device_python(0x80, REGADDR)  # Register set
read_data = pcie_rwlib.read_from_device_python(REGADDR)

print("wait GPU result")
time.sleep(0.1)

# GPU Stop
pcie_rwlib.write_to_device_python(0x00, REGADDR)  # Register set

# Debug
print("\nDebug")
pcie_rwlib.write_to_device_python(0x02, REGADDR)  # Register set
read_data = pcie_rwlib.read_from_device_python(0x0038)
read_data = pcie_rwlib.read_from_device_python(0x003C)

print("\nGPU Output")
for addr in range(0x0080, 0x00bc, 0x4):
    read_data = pcie_rwlib.read_from_device_python(addr)
    #print(f"Read data from address {hex(addr)}: {read_data}")
    print(f"Read data from address {hex(addr)}: {fp16_to_float(read_data)}")

# GPU ソフトリセット
print("\nGPU Reset")
pcie_rwlib.write_to_device_python(0x100, REGADDR)  # Register set
pcie_rwlib.write_to_device_python(0x000, REGADDR)  # Register set

# 最終デバッグ出力
print("Debug")

def float_to_fp16(value):
    # Convert to 32-bit float representation
    packed = struct.pack('>f', value)
    int_rep = struct.unpack('>I', packed)[0]

    # Extract sign, exponent, and mantissa
    sign = (int_rep >> 31) & 0x1
    exp = (int_rep >> 23) & 0xFF
    mantissa = int_rep & 0x7FFFFF

    # Convert to 16-bit floating point
    if exp == 0:  # Zero or subnormal
        exp_fp16 = 0
        mantissa_fp16 = 0
    elif exp == 0xFF:  # Inf or NaN
        exp_fp16 = 0x1F
        mantissa_fp16 = (mantissa != 0) * 0x200  # NaN has a non-zero mantissa
    else:
        exp_fp16 = max(0, min(0x1F, exp - 127 + 15))
        mantissa_fp16 = mantissa >> 13

    # Assemble 16-bit result
    fp16 = (sign << 15) | (exp_fp16 << 10) | mantissa_fp16
    return fp16

def fp16_to_float(fp16):
    # Extract sign, exponent, and mantissa from 16-bit representation
    sign = (fp16 >> 15) & 0x1
    exp = (fp16 >> 10) & 0x1F
    mantissa = fp16 & 0x3FF

    if exp == 0:  # Zero or subnormal
        if mantissa == 0:
            return (-1)**sign * 0.0
        else:
            return (-1)**sign * (mantissa / 2**10) * 2**(-14)
    elif exp == 0x1F:  # Inf or NaN
        if mantissa == 0:
            return float('inf') if sign == 0 else float('-inf')
        else:
            return float('nan')
    else:
        return (-1)**sign * (1 + mantissa / 2**10) * 2**(exp - 15)
