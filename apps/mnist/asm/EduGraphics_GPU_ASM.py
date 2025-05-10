import sys
import os
import struct 

# 命令セットのオペコードを定義
instruction_set = {
    "NOP":    "0000",
    "BR":     "0001",  # BR命令を一般化
    "BRN":    "0001",
    "BRZ":    "0001",
    "BRP":    "0001",
    "BRNZP":  "0001",
    "CMP":    "0010",
    "ADD":    "0011",
    "SUB":    "0100",
    "MUL":    "0101",
    "FMUL":   "1101",
    "DIV":    "0110",
    "LDR":    "0111",
    "STR":    "1000",
    "CONST":  "1001",
    "RET":    "1111"
}

# レジスタを2進数に変換するための辞書
registers = {f"R{i}": f"{i:04b}" for i in range(16)}
# 特殊変数をレジスタにマッピング
special_variables = {
    "%blockIdx": "R13",
    "%blockDim": "R14",
    "%threadIdx": "R15"
}

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

def first_pass(lines):
    """第一パス: ラベルのアドレスを収集し、ディレクティブを処理"""
    labels = {}
    address = 0  # 命令の位置（アドレス）
    data_segment = []
    thread_count = None

    for line_num, line in enumerate(lines):
        # コメントを除去
        if ';' in line:
            line_content, _ = line.split(';', 1)
        else:
            line_content = line
        line_content = line_content.strip()
        if not line_content:
            continue  # 空行は無視

        tokens = line_content.split()
        if len(tokens) == 0:
            continue

        # ディレクティブの処理
        if tokens[0].startswith('.'):
            directive = tokens[0]
            if directive == '.threads':
                # スレッド数の設定
                if len(tokens) >= 2:
                    thread_count = int(tokens[1])
                else:
                    raise ValueError(f"'.threads' ディレクティブにスレッド数が指定されていません（行 {line_num + 1}）")
            elif directive == '.fdata':
                data_values = tokens[1:]
                for value in data_values:
                    fp16_value = float_to_fp16(float(value))
                    data_segment.append(fp16_value)
            elif directive == '.data':
                # データセグメントへのデータ追加
                data_values = tokens[1:]
                for value in data_values:
                    data_segment.append(int(value, 0))  # 0x, 0b に対応
            else:
                print(f"警告: 未知のディレクティブ '{directive}' を無視します。")
            continue

        # ラベルの処理
        if tokens[0].endswith(':'):
            label = tokens[0][:-1]
            labels[label] = address
            continue

        address += 1  # 命令がある行ではアドレスを増やす

    return labels, data_segment, thread_count

def assemble_line(line, labels, address):
    """アセンブリ命令を機械語に変換"""
    # コメントを保持
    if ';' in line:
        line_content, comment = line.split(';', 1)
        comment = comment.strip()
    else:
        line_content = line
        comment = ''
    line_content = line_content.strip()
    if not line_content:
        return None, 0  # 空行は無視

    original_instruction = line_content  # アセンブリ命令全体を保存

    tokens = line_content.split()
    if len(tokens) == 0:
        return None, 0

    # ディレクティブの処理（ここでは無視）
    if tokens[0].startswith('.'):
        return None, 0  # ディレクティブは first_pass で処理済み

    # ラベルの処理
    if tokens[0].endswith(':'):
        label_name = tokens[0][:-1]
        return ('LABEL', label_name, None), 0  # ラベル行を示す特別な戻り値

    # トークンの前処理
    tokens = [token.strip(',:') for token in tokens]

    # 特殊変数をレジスタに置き換え
    tokens = [special_variables.get(token, token) for token in tokens]

    if len(tokens) == 0:
        return None, 0

    instruction = tokens[0].upper()

    if instruction not in instruction_set:
        raise ValueError(f"不明な命令: {instruction}")

    opcode = instruction_set[instruction]

    # NOP, RET の場合
    if instruction == "NOP" or instruction == "RET":
        machine_code_instruction = opcode + "000000000000"
        return (machine_code_instruction, original_instruction, comment), 1

    # BR 命令の場合（BR, BRN, BRZ, BRP, BRNZP）
    if instruction.startswith("BR"):
        # フラグを設定（N, Z, P, X）
        flags = instruction[2:]  # "BR"に続くフラグ
        if not flags:
            flags = "NZPX"  # フラグがない場合はすべてを有効に
        n_flag = '1' if 'N' in flags else '0'
        z_flag = '1' if 'Z' in flags else '0'
        p_flag = '1' if 'P' in flags else '0'
        x_flag = '1' if 'X' in flags else '0'
        # フラグの順序を N Z P X に設定
        pznx_flags = n_flag + z_flag + p_flag + x_flag

        if len(pznx_flags) != 4:
            raise ValueError(f"フラグはN, Z, P, Xのいずれかで指定してください: {flags}")

        # ブランチ命令の即値を絶対アドレスとして計算
        target = tokens[1]
        if target in labels:
            imm8 = labels[target] & 0xFF  # 絶対アドレスを設定
        else:
            try:
                imm8 = int(target.lstrip('#'), 0) & 0xFF
            except ValueError:
                raise ValueError(f"ラベル {target} が見つかりません。")

        imm8_bin = f"{imm8:08b}"
        machine_code_instruction = opcode + pznx_flags + imm8_bin
        return (machine_code_instruction, original_instruction, comment), 1

    # CONST 命令の場合
    if instruction == "CONST":
        rd = tokens[1].upper()
        if rd not in registers:
            raise ValueError(f"不明なレジスタ: {rd}")
        rd_bin = registers[rd]
        imm8 = tokens[2].lstrip('#')
        imm8 = int(imm8, 0) & 0xFF  # 0x または 0b に対応
        imm8_bin = f"{imm8:08b}"
        machine_code_instruction = opcode + rd_bin + imm8_bin
        return (machine_code_instruction, original_instruction, comment), 1

    # CMP 命令の場合
    if instruction == "CMP":
        rs = tokens[1].upper()
        rt = tokens[2].upper()
        if rs not in registers or rt not in registers:
            raise ValueError(f"不明なレジスタ: {rs}, {rt}")
        rs_bin = registers[rs]
        rt_bin = registers[rt]
        machine_code_instruction = opcode + "0000" + rs_bin + rt_bin
        return (machine_code_instruction, original_instruction, comment), 1

    # LDR 命令の場合
    if instruction == "LDR":
        rd = tokens[1].upper()
        rs = tokens[2].upper()
        if rd not in registers or rs not in registers:
            raise ValueError(f"不明なレジスタ: {rd}, {rs}")
        rd_bin = registers[rd]
        rs_bin = registers[rs]
        machine_code_instruction = opcode + rd_bin + rs_bin + "0000"
        return (machine_code_instruction, original_instruction, comment), 1

    # STR 命令の場合
    if instruction == "STR":
        rs = tokens[1].upper()
        rt = tokens[2].upper()
        if rs not in registers or rt not in registers:
            raise ValueError(f"不明なレジスタ: {rs}, {rt}")
        rs_bin = registers[rs]
        rt_bin = registers[rt]
        machine_code_instruction = opcode + "0000" + rs_bin + rt_bin
        return (machine_code_instruction, original_instruction, comment), 1

    # R形式（ADD, SUB, MUL, DIV）の場合
    rd = tokens[1].upper()
    rs = tokens[2].upper()
    rt = tokens[3].upper() if len(tokens) > 3 else "R0"  # Rtがない場合はR0を使用
    if rd not in registers or rs not in registers or rt not in registers:
        raise ValueError(f"不明なレジスタ: {rd}, {rs}, {rt}")
    rd_bin = registers[rd]
    rs_bin = registers[rs]
    rt_bin = registers[rt]
    machine_code_instruction = opcode + rd_bin + rs_bin + rt_bin
    return (machine_code_instruction, original_instruction, comment), 1

def assemble_code(assembly_code):
    """アセンブリコード全体を機械語に変換"""
    lines = assembly_code.splitlines()
    labels, data_segment, thread_count = first_pass(lines)  # 第一パスでラベルとデータを収集

    address = 0  # 命令の位置（アドレス）
    machine_code_output = []
    instruction_lines = []  # 命令行のみを保持
    for line_num, line in enumerate(lines):
        try:
            result, increment = assemble_line(line, labels, address)
            if result:
                if result[0] == 'LABEL':
                    label_name = result[1]
                    machine_code_output.append(f"# {label_name}:")
                else:
                    machine_code_instruction, original_instruction, comment = result
                    binary_instruction = '0b' + machine_code_instruction
                    # コメント内のカンマをセミコロンに置換
                    comment = comment.replace(',', ';')
                    original_instruction = original_instruction.replace(',', ';')
                    if comment:
                        formatted_line = f"{binary_instruction}  # {original_instruction}  ; {comment}"
                    else:
                        formatted_line = f"{binary_instruction}  # {original_instruction}"
                    machine_code_output.append(formatted_line)
                    instruction_lines.append(formatted_line)
                    address += increment
            elif increment > 0:
                address += increment
        except Exception as e:
            print(f"エラー（行 {line_num + 1}）: {e}")

    return machine_code_output, instruction_lines, data_segment, thread_count

def main():
    if len(sys.argv) != 2:
        print("使用法: python EduGraASM.py <アセンブリファイル名>")
        sys.exit(1)

    input_file = sys.argv[1]

    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            assembly_code = f.read()


        # アセンブル実行
        machine_code_output, instruction_lines, data_segment, thread_count = assemble_code(assembly_code)

        # ファイル名の生成
        base_name = os.path.splitext(input_file)[0]
        code_file_name = base_name + '_code.py'
        data_file_name = base_name + '_data.py'

        # 機械語のプログラム部分をファイルに保存（Pythonのリストとして）
        with open(code_file_name, 'w') as code_file:
            code_file.write("program = [\n")
            instruction_count = len(machine_code_output)
            for idx, line in enumerate(machine_code_output):
                if line.startswith("#"):
                    code_file.write(f"    {line}\n")
                else:
                    instruction_part, *rest = line.split('#', 1)
                    instruction_part = instruction_part.strip()
                    comment_part = '#' + rest[0].strip() if rest else ''
                    if idx < instruction_count - 1:
                        code_file.write(f"    {instruction_part}, {comment_part}\n")
                    else:
                        code_file.write(f"    {instruction_part} {comment_part}\n")  # 最後の行の後ろにカンマを付けない
            code_file.write("]\n")

        # データセグメントをファイルに保存（Pythonのリストとして）
        with open(data_file_name, 'w', encoding='utf-8') as data_file:
            data_file.write("data = [\n")
            for idx, data_value in enumerate(data_segment):
                if idx < len(data_segment) - 1:
                    data_file.write(f"    {data_value},\n")
                else:
                    data_file.write(f"    {data_value}\n")
            data_file.write("]\n")

        print(f"機械語のプログラム部分を '{code_file_name}' に保存しました。")
        print(f"データセグメントを '{data_file_name}' に保存しました。")

    except FileNotFoundError:
        print(f"エラー: ファイル '{input_file}' が見つかりません。")
    except Exception as e:
        print(f"エラー: {e}")

if __name__ == "__main__":
    main()
