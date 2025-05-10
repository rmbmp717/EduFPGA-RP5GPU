import pcie_rwlib
import time

REGADDR    = 0xF800
THREADADDR = 0xF400

GPU_WAITTIME = 0.001

# 自作FP16ライブラリのインポート
import fp16_lib

from asm import assm5_code
program = [(instruction, idx * 0x04) for idx, instruction in enumerate(assm5_code.program)]
#print("Loaded Program:", program)  # デバッグ出力で program の内容を確認

def transfer_program_to_gpu(program):

    print("Thread num set")
    pcie_rwlib.write_to_device_python(0x08, THREADADDR)  # Register set
    #read_data = pcie_rwlib.read_from_device_python(THREADADDR)

    pcie_rwlib.write_to_device_python(0x01, REGADDR)  # Register set
    #read_data = pcie_rwlib.read_from_device_python(REGADDR)

    PROGRAM_ADDR = 0x0000
    
    for idx, (instruction, _) in enumerate(program):  # タプルの最初の要素を取り出す
        address = PROGRAM_ADDR + idx * 0x4  # Each instruction is 4 bytes apart
        #print(f"Transferring instruction {hex(instruction)} to address {hex(address)}")
        pcie_rwlib.write_to_device_python(instruction, address)

    print("Program transfer completed successfully.")

def run_gpu():
    """GPUを実行し、処理が完了するまで待機"""
    #print("Starting GPU execution")
    pcie_rwlib.write_to_device_python(0x00, REGADDR)  # 実行開始
    pcie_rwlib.write_to_device_python(0x80, REGADDR)  # 実行トリガー

    # GPU_done信号の読出し
    for i in range(10):
        #time.sleep(0.00000001)  # GPU処理の完了まで待機
        read_data = pcie_rwlib.read_from_device_python(REGADDR)
        #print(f"REGADDR Read Data: {hex(read_data)}")  # 確認用出力
        if read_data == 0x8080 :
            break

    #print("Stopping GPU")
    pcie_rwlib.write_to_device_python(0x00, REGADDR)  # 実行停止

    # GPU Soft Reset
    #print("GPU Soft Reset")
    pcie_rwlib.write_to_device_python(0x100, REGADDR)  # Register set
    pcie_rwlib.write_to_device_python(0x000, REGADDR)  # Register reset

def read_gpu_results(num):
    """GPUの実行結果を読み出し、表示"""
    print("Reading GPU results")
    pcie_rwlib.write_to_device_python(0x02, REGADDR)  # レジスタ設定

    results = []
    #for i in range(RESULT_COUNT):
    for i in range(num):
        #address = RESULT_ADDR_START + i * 0x4
        address = 0x00 + i * 0x4
        read_data = pcie_rwlib.read_from_device_python(address)
        if(i==1 or i==2):
            results.append(read_data)
            print(f"DataNum: {i}: Read data from address {hex(address)}: {read_data}")
        else:
            results.append(fp16_lib.fp16_to_float(read_data))
            print(f"DataNum: {i}: Read data from address {hex(address)}: {fp16_lib.fp16_to_float((read_data))}")
            #print(f"DataNum: {i}: Read data from address {hex(address)}: {read_data}")

def calculate_dot_product(x, weights, data_addr=0x020):    

    # Transfer the GPU Data to the device
    #print("Write Data memory")
    pcie_rwlib.write_to_device_python(0x02, REGADDR)  # Register set
    read_data = pcie_rwlib.read_from_device_python(REGADDR)
    
    # 0x00
    # Write input value x to a fixed address (0x00)
    #print("Write input x to device")
    #print("x=", x)
    xi_fp16 = fp16_lib.float_to_fp16(x)  # Assuming a single input for simplicity
    pcie_rwlib.write_to_device_python(xi_fp16, 0x00)
    read_data = pcie_rwlib.read_from_device_python(0x00)
    #print(f"Read back x from address 0x00: {fp16_lib.fp16_to_float(read_data)}") 

    # 0x04
    # Write Data number (addr=0x04)
    #print("Data number. len(w)=", len(w))
    pcie_rwlib.write_to_device_python(len(weights)+8, 0x04)
    read_data = pcie_rwlib.read_from_device_python(0x04)
    #print(f"Read back Data from address 0x04: {int(read_data)}") 

    # 0x08
    # Write Output Data Start address (addr=0x08)
    #print(f"Write Start address=", hex(0x04*(len(w)+16)))
    pcie_rwlib.write_to_device_python(int(len(weights)+8+16), 0x08)
    read_data = pcie_rwlib.read_from_device_python(0x08)
    #print(f"Read back Data from address 0x08: {int(read_data)}") 
    
    # ================ Data Write =========================================
    # Write weights w to device starting from data_addr (0x20)
    #print("Write weights w to device")
    offset = 0x00 
    i = 0
    for wi in weights:
        # Convert the weight to fp16 format
        wi_fp16 = fp16_lib.float_to_fp16(wi)
        # Write the fp16 weight to the device
        write_address = data_addr + offset
        pcie_rwlib.write_to_device_python(wi_fp16, write_address)
        #print(f"Written data {fp16_lib.fp16_to_float(wi_fp16)} to address {hex(write_address)}")
        # Read back the value to verify
        #read_data = pcie_rwlib.read_from_device_python(write_address)
        #print(f"i:{i}: Read data from address {hex(write_address)}: {fp16_lib.fp16_to_float(read_data)}")
        offset += 0x04
        i += 1

    # ================ GPU Run =========================================
    # Trigger computation on the GPU
    #print("Start GPU computation")
    run_gpu()

    # ================ Data Read =========================================
    # Read Data Memory mode
    #print("Write Data memory")
    pcie_rwlib.write_to_device_python(0x02, REGADDR)  # Register set
    read_data = pcie_rwlib.read_from_device_python(REGADDR) 

    #results = read_gpu_results(2*len(weights)+16)  # 実行結果の読み出し
    
    results = []
    i = 0
    for addr in range(0x04 * (len(weights) + 8 + 16), 0x04 * (2*len(weights) + 8 + 16), 0x4):
        read_data = pcie_rwlib.read_from_device_python(addr)
        result_float = fp16_lib.fp16_to_float(read_data)
        #result_cpu = x * weights[i]
        results.append(result_float)
        #results.append(result_cpu)
        #print(f"i: {i}: Read data from address {hex(addr)}: {result_float}")
        '''
        if abs(result_float-x*weights[i]) > abs(0.001*x*weights[i]) and abs(x*weights[i]) > 0.001:
            print(f"Err. i= {i}. GPU result: {result_float}. Raspi CPU result: {x*weights[i]}. addr: {hex(addr)}. x= {x}, weight= {weights[i]}")
            print(f"Err rate = {abs(result_float-x*weights[i])/abs(x*weights[i])}")
        '''
        i += 1

    # GPU Soft Reset
    #print("GPU Soft Reset")
    pcie_rwlib.write_to_device_python(0x100, REGADDR)  # Register set
    pcie_rwlib.write_to_device_python(0x000, REGADDR)  # Register reset

    return results