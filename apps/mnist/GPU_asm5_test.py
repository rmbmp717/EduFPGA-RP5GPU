import time
import fp16_lib
import pcie_rwlib
from asm import assm5_code

# 定数の設定
REGADDR = 0xF800
THREADADDR = 0xF400
PROGRAM_ADDR = 0x0000
PARAMETER_ADDR = 0x000
DATA_ADDR      = 0x020
RESULT_ADDR_START = 0x040
RESULT_COUNT = 8  # 読み出す結果の個数

# プログラムデータの準備
program = [(instruction, idx * 0x04) for idx, instruction in enumerate(assm5_code.program)]

def transfer_program_to_gpu(program):
    """GPUにプログラムを転送し、正しく転送されたかを検証"""
    print("\nThread num set")
    pcie_rwlib.write_to_device_python(0x08, THREADADDR)  # スレッド数の設定
    pcie_rwlib.write_to_device_python(0x01, REGADDR)     # レジスタ設定

    # プログラムデータをGPUに転送
    for idx, (instruction, _) in enumerate(program):
        address = PROGRAM_ADDR + idx * 0x4
        pcie_rwlib.write_to_device_python(instruction, address)
        print(f"Written instruction {hex(instruction)} to address {hex(address)}")

        # データの検証
        read_data = pcie_rwlib.read_from_device_python(address)
        print(f"Read data from address {hex(address)}: {hex(read_data)}")
        if read_data == instruction:
            print("Verification passed.")
        else:
            print("Verification failed. Mismatch between written and read data.")

    print("Program transfer and verification completed successfully.")

def write_and_verify_data(parameters, weights):
    """データを書き込み、正しく書き込まれたかを検証"""
    print("\nWrite test weights to device and verify")
    pcie_rwlib.write_to_device_python(0x02, REGADDR)  # レジスタ設定

    # parametgers
    data_num = 0
    offset = 0
    for parameter in parameters:
        address = PARAMETER_ADDR + offset
        if data_num == 0:
            # data_num が 0 のときだけ FP16 に変換
            pcie_rwlib.write_to_device_python(fp16_lib.float_to_fp16(parameter), address)
        else:
            # それ以外の場合はそのまま書き込み
            pcie_rwlib.write_to_device_python(parameter, address)
        
        # 書き込んだデータの検証
        read_data = pcie_rwlib.read_from_device_python(address)
        if(data_num==0):
            read_data = fp16_lib.fp16_to_float(read_data)
        if abs(read_data - parameter) < 0.01 * abs(read_data):
            print(f"DataNum: {data_num}: Address {hex(address)}: Written {parameter}, Read {read_data} - Passed")
        else:
            print(f"DataNum: {data_num}: Address {hex(address)}: Written {parameter}, Read {read_data} - Failed")
        data_num += 1
        offset += 0x4

    # weights
    data_num = 0
    offset = 0
    for weight in weights:
        weight_fp16 = fp16_lib.float_to_fp16(weight)
        address = DATA_ADDR + offset
        pcie_rwlib.write_to_device_python(weight_fp16, address)
        
        # 書き込んだデータの検証
        read_data = pcie_rwlib.read_from_device_python(address)
        real_read_data = fp16_lib.fp16_to_float(read_data)
        if real_read_data == weight:
            print(f"DataNum: {data_num}: Address {hex(address)}: Written {weight}, Read {real_read_data} - Passed")
        else:
            print(f"DataNum: {data_num}: Address {hex(address)}: Written {weight}, Read {real_read_data} - Failed")
        data_num += 1
        offset += 0x4

def clear_data_memory(end_address):
    pcie_rwlib.write_to_device_python(0x02, REGADDR)  # レジスタ設定
    
    for wadd in range(0, end_address, 0x04):  # アドレスを4バイトごとに進める
        pcie_rwlib.write_to_device_python(0x00, wadd)  # 0x00 を指定アドレスに書き込む
        print(f"Cleared address {hex(wadd)}")  # 確認用出力

def run_gpu():
    """GPUを実行し、処理が完了するまで待機"""
    print("Starting GPU execution")
    pcie_rwlib.write_to_device_python(0x00, REGADDR)  # 実行開始
    pcie_rwlib.write_to_device_python(0x80, REGADDR)  # 実行トリガー

    # GPU_done信号の読出し
    for i in range(10):
        #time.sleep(0.00000001)  # GPU処理の完了まで待機
        read_data = pcie_rwlib.read_from_device_python(REGADDR)
        #print(f"REGADDR Read Data: {hex(read_data)}")  # 確認用出力
        if read_data == 0x8080 :
            break

    print("Stopping GPU")
    pcie_rwlib.write_to_device_python(0x00, REGADDR)  # 実行停止

    # GPU Soft Reset
    print("GPU Soft Reset")
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

    return results

def gpu_results_check(num, parameters, test_weights):
    """GPUの実行結果を読み出し、表示"""
    print("Reading GPU results & check")
    pcie_rwlib.write_to_device_python(0x02, REGADDR)  # レジスタ設定

    results = []
    #for i in range(RESULT_COUNT):
    for i in range(num):
        address = 0x00 + i * 0x4
        read_data = pcie_rwlib.read_from_device_python(address)
        if(i==0):
            x_float_read_data = fp16_lib.fp16_to_float(read_data)
            if abs(x_float_read_data-parameters[0]) > 0.001*parameters[0] : 
                print("err")
        elif(i==1):
            print(f"DataNum: {i}: Read data from address {hex(address)}: {read_data}")
            if read_data != parameters[1]:
                print("err")
        elif(i==2):
            print(f"DataNum: {i}: Read data from address {hex(address)}: {read_data}")
            if read_data != parameters[1]:
                print("err")
        elif(i>=80):
            float_read_data = fp16_lib.fp16_to_float(read_data)
            print(f"DataNum: {i}: Read data from address {hex(address)}: {float_read_data}")
            print(f"read_data: {float_read_data}, x*test_weight: {x_float_read_data*test_weights[i-80]}")
            if abs(float_read_data-x_float_read_data*test_weights[i-80]) > 0.05*abs(x_float_read_data*test_weights[i-80]) :
                print(f"Err! : read_data: {float_read_data}, x*test_weight: {x_float_read_data*test_weights[i-80]}")
                print(f"Err rate = {abs(float_read_data-x_float_read_data*test_weights[i-80])/abs(x_float_read_data*test_weights[i-80])}")
        else:
            print(f"DataNum: {i}: Read data from address {hex(address)}: {fp16_lib.fp16_to_float((read_data))}")

def test_asm5_full():

    clear_data_memory(0x300)

    transfer_program_to_gpu(program)  # プログラムの転送と検証

    parameters   = [0.001, 64, (64+16), 0, 0, 0, 0, 0]
    test_weights = [-0.020660400390625, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0,
                    1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0,
                    8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0,
                    2.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0,
                    8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0,
                    3.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0,
                    8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0,
                    4.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 99.0]

    write_and_verify_data(parameters, test_weights)  # データ書き込みと検証

    for i in range(1):
        run_gpu()  # GPUの実行

    results = read_gpu_results(160)  # 実行結果の読み出し

    gpu_results_check((2*parameters[1]+16), parameters, test_weights)

    print("Input GPU data", test_weights)
    print("Final GPU Results:", results)

# テストの実行
if __name__ == "__main__":
    test_asm5_full()
