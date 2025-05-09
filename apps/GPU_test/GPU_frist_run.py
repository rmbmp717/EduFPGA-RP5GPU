import pcie_rwlib
import time

REGADDR     = 0xF800
THREADADDR  = 0xF400

#プログラムメモリに書き込む
print("\nWrite Program memory")
pcie_rwlib.write_to_device_python(0x01, REGADDR)  # Register set
read_data = pcie_rwlib.read_from_device_python(REGADDR)

pcie_rwlib.write_to_device_python(0b0101000011011110, 0x0000)   # MUL R0, %blockIdx, %blockDim
pcie_rwlib.write_to_device_python(0b0011000000001111, 0x0004)   # ADD R0, R0, %threadIdx 
pcie_rwlib.write_to_device_python(0b1001000100000000, 0x0008)   # CONST R1, #0   
pcie_rwlib.write_to_device_python(0b1001001000001000, 0x000C)   # CONST R2, #8
pcie_rwlib.write_to_device_python(0b1001001100010000, 0x0010)   # CONST R3, #16   
pcie_rwlib.write_to_device_python(0b0011010000010000, 0x0014)   # ADD R4, R1, R0      
pcie_rwlib.write_to_device_python(0b0111010001000000, 0x0018)   # LDR R4, R4   
pcie_rwlib.write_to_device_python(0b0011010100100000, 0x001C)   # ADD R5, R2, R0   
pcie_rwlib.write_to_device_python(0b0111010101010000, 0x0020)   # LDR R5, R5      
pcie_rwlib.write_to_device_python(0b0011011001000101, 0x0024)   # ADD R6, R4, R5 
pcie_rwlib.write_to_device_python(0b0011011100110000, 0x0028)   # ADD R7, R3, R0 
pcie_rwlib.write_to_device_python(0b1000000001110110, 0x002C)   # STR R7, R6
pcie_rwlib.write_to_device_python(0b1111000000000000, 0x0030)   # RET  
pcie_rwlib.write_to_device_python(0x000, 0x0034) 

print("\nProgram Data check")
read_data = pcie_rwlib.read_from_device_python(0x0000)
read_data = pcie_rwlib.read_from_device_python(0x0004)
read_data = pcie_rwlib.read_from_device_python(0x0008)
read_data = pcie_rwlib.read_from_device_python(0x000C)
read_data = pcie_rwlib.read_from_device_python(0x0010)
read_data = pcie_rwlib.read_from_device_python(0x0014)
read_data = pcie_rwlib.read_from_device_python(0x0018)
read_data = pcie_rwlib.read_from_device_python(0x001C)
read_data = pcie_rwlib.read_from_device_python(0x0020)
read_data = pcie_rwlib.read_from_device_python(0x0024)
read_data = pcie_rwlib.read_from_device_python(0x0028)
read_data = pcie_rwlib.read_from_device_python(0x002C)
read_data = pcie_rwlib.read_from_device_python(0x0030)
read_data = pcie_rwlib.read_from_device_python(0x0034)

#データメモリに書き込む
print("\nWrite Data memory")
pcie_rwlib.write_to_device_python(0x02, REGADDR)  # Register set
read_data = pcie_rwlib.read_from_device_python(REGADDR)

pcie_rwlib.write_to_device_python(0x00, 0x0000)
pcie_rwlib.write_to_device_python(0x01, 0x0004)
pcie_rwlib.write_to_device_python(0x02, 0x0008) 
pcie_rwlib.write_to_device_python(0x03, 0x000C) 
pcie_rwlib.write_to_device_python(0x04, 0x0010)
pcie_rwlib.write_to_device_python(0x05, 0x0014) 
pcie_rwlib.write_to_device_python(0x06, 0x0018) 
pcie_rwlib.write_to_device_python(0x07, 0x001C) 

pcie_rwlib.write_to_device_python(0x00, 0x0020)
pcie_rwlib.write_to_device_python(0x01, 0x0024)
pcie_rwlib.write_to_device_python(0x02, 0x0028) 
pcie_rwlib.write_to_device_python(0x03, 0x002C) 
pcie_rwlib.write_to_device_python(0x04, 0x0030)
pcie_rwlib.write_to_device_python(0x05, 0x0034) 
pcie_rwlib.write_to_device_python(0x06, 0x0038) 
pcie_rwlib.write_to_device_python(0x07, 0x003C) 

print("\nData Memory Data check")
read_data = pcie_rwlib.read_from_device_python(0x0000)
read_data = pcie_rwlib.read_from_device_python(0x0004)
read_data = pcie_rwlib.read_from_device_python(0x0008)
read_data = pcie_rwlib.read_from_device_python(0x000C)
read_data = pcie_rwlib.read_from_device_python(0x0010)
read_data = pcie_rwlib.read_from_device_python(0x0014)
read_data = pcie_rwlib.read_from_device_python(0x0018)
read_data = pcie_rwlib.read_from_device_python(0x001C)

read_data = pcie_rwlib.read_from_device_python(0x0020)
read_data = pcie_rwlib.read_from_device_python(0x0024)
read_data = pcie_rwlib.read_from_device_python(0x0028)
read_data = pcie_rwlib.read_from_device_python(0x002C)
read_data = pcie_rwlib.read_from_device_python(0x0030)
read_data = pcie_rwlib.read_from_device_python(0x0034)
read_data = pcie_rwlib.read_from_device_python(0x0038)
read_data = pcie_rwlib.read_from_device_python(0x003C)

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
read_data = pcie_rwlib.read_from_device_python(0x0040)
read_data = pcie_rwlib.read_from_device_python(0x0044)
read_data = pcie_rwlib.read_from_device_python(0x0048)
read_data = pcie_rwlib.read_from_device_python(0x004C)
read_data = pcie_rwlib.read_from_device_python(0x0050)
read_data = pcie_rwlib.read_from_device_python(0x0054)
read_data = pcie_rwlib.read_from_device_python(0x0050)
read_data = pcie_rwlib.read_from_device_python(0x005C)

#GPUソフトリセット
print("\nGPU Reset")
pcie_rwlib.write_to_device_python(0x100, REGADDR)  # Register set
pcie_rwlib.write_to_device_python(0x000, REGADDR)  # Register set

#read_data = pcie_rwlib.read_from_device_python(REGADDR)

# Debug
print("Debug")
#pcie_rwlib.write_to_device_python(0x80, REGADDR)  # Register set
#read_data = pcie_rwlib.read_from_device_python(0x040)

