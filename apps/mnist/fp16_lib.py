import struct

def float_to_fp16(value):
    packed = struct.pack('>f', value)
    int_rep = struct.unpack('>I', packed)[0]
    sign = (int_rep >> 31) & 0x1
    exp = (int_rep >> 23) & 0xFF
    mantissa = int_rep & 0x7FFFFF
    if exp == 0:
        exp_fp16 = 0
        mantissa_fp16 = 0
    elif exp == 0xFF:
        exp_fp16 = 0x1F
        mantissa_fp16 = (mantissa != 0) * 0x200
    else:
        exp_fp16 = max(0, min(0x1F, exp - 127 + 15))
        mantissa_fp16 = mantissa >> 13
    fp16 = (sign << 15) | (exp_fp16 << 10) | mantissa_fp16
    return fp16

def fp16_to_float(fp16):
    sign = (fp16 >> 15) & 0x1
    exp = (fp16 >> 10) & 0x1F
    mantissa = fp16 & 0x3FF
    if exp == 0:
        if mantissa == 0:
            return (-1)**sign * 0.0
        else:
            return (-1)**sign * (mantissa / 2**10) * 2**(-14)
    elif exp == 0x1F:
        if mantissa == 0:
            return float('inf') if sign == 0 else float('-inf')
        else:
            return float('nan')
    else:
        return (-1)**sign * (1 + mantissa / 2**10) * 2**(exp - 15)