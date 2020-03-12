#!/usr/bin/env python
# coding=utf-8
# Build Version: Python3
import base64
import binascii
import sys
from pyDes import *

def DesEncrypt(str, Des_Key):
    k = des(Des_Key, ECB, pad=None)
    EncryptStr = k.encrypt(str)
    return binascii.b2a_hex(EncryptStr)


def Zero_padding(str):
    b = []
    l = len(str)
    num = 0
    for n in range(l):
        if (num < 8) and n % 7 == 0:
            b.append(str[n:n + 7] + '0')
            num = num + 1
    return ''.join(b)


if __name__ == "__main__":
    try:
      #将输入值进行Bytes转换
      print("Password : "+sys.argv[1])
      test_str = sys.argv[1].encode('utf-8')
    except Exception as e:
      print("Usage:Python LM-Hashes.py Password")
      print("[*] Error:"+str(e))
      sys.exit()
    # 用户的密码转换为大写,并转换为16进制ASCCI;
    test_str = test_str.upper()
    test_str = binascii.b2a_hex(test_str).decode();
    print("Hex: "+test_str)
    str_len = len(test_str)

    # 密码不足14字节将会用0来补全
    if str_len < 28:
        test_str = test_str.ljust(28, '0')

    # 固定长度的密码被分成两个7byte部分
    t_1 = test_str[0:14]
    t_2 = test_str[14:]

    # print(t_1 + " " + t_2)

    # 每部分转换成比特流，并且长度位56bit，长度不足使用0在左边补齐长度
    t_1 = bin(int(t_1, 16)).lstrip('0b').rjust(56, '0')
    t_2 = bin(int(t_2, 16)).lstrip('0b').rjust(56, '0')

    # 再分7bit为一组末尾加0，组成新的编码
    t_1 = Zero_padding(t_1)
    t_2 = Zero_padding(t_2)
    #print(t_1)
    t_1 = hex(int(t_1, 2))
    t_2 = hex(int(t_2, 2))
    t_1 = t_1[2:].rstrip('L')
    t_2 = t_2[2:].rstrip('L')

    if '0' == t_2:
        t_2 = "0000000000000000"
    t_1 = binascii.a2b_hex(t_1)
    t_2 = binascii.a2b_hex(t_2)

    # 上步骤得到的8byte二组，分别作为DES key为"KGS!@#$%"进行加密。
    LM_1 = DesEncrypt("KGS!@#$%", t_1)
    LM_2 = DesEncrypt("KGS!@#$%", t_2)

    # 将二组DES加密后的编码拼接，得到最终LM HASH值。
    LM = LM_1 + LM_2
    print("LM-Hashse Lower: "+LM.decode()+ "\nLM-Hashes Upper: "+LM.decode().upper())