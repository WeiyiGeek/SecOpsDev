#!/usr/bin/env python
# coding=utf-8
# Build Version: Python3
# Author: WeiyiGeek
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
      print("LM-Hashes : "+sys.argv[1])
      print("Challenge : "+sys.argv[2])
      LMHashes = sys.argv[1]
      #将输入值进行Bytes转换
      #注意这里不能直接传入String字符串需要转成bytes再返回十六进制字符串hexstr表示的二进制数据。
      Challenge=binascii.a2b_hex(sys.argv[2].encode('utf-8'))
    except Exception as e:
      print("Usage:Python LM-Response.py LM-Hashed Challenge");
      print("[*] Error:"+str(e))
      sys.exit()

    print(Challenge)
    
     #LM-Hashes不足21B时进行补0;
    if len(LMHashes) < 42:
        LMHashes = LMHashes.ljust(42, '0')

     # 固定长度的密码被分成三个7byte部分
    t_1 = LMHashes[0:14]
    t_2 = LMHashes[14:28]
    t_3 = LMHashes[28:]

    t_1 = bin(int(t_1, 16)).lstrip('0b').rjust(56, '0')
    t_2 = bin(int(t_2, 16)).lstrip('0b').rjust(56, '0')
    t_3 = bin(int(t_3, 16)).lstrip('0b').rjust(56, '0')

    #str_to_key()函数处理原理
    #每组56bit再分7bit为一组末尾加0，组成新的编码并转换成为三组DESKEY
    t_1 = Zero_padding(t_1)
    t_2 = Zero_padding(t_2)
    t_3 = Zero_padding(t_3)

    #将二进制转成十进制然后转成16进制
    t_1 = hex(int(t_1, 2))
    t_2 = hex(int(t_2, 2))
    t_3 = hex(int(t_3, 2))
   

    #以右为基准在左添加补齐0补齐16进行
    t_1 = t_1[2:].rstrip('L').rjust(16, '0')
    t_2 = t_2[2:].rstrip('L').rjust(16, '0')
    t_3 = t_3[2:].rstrip('L').rjust(16, '0')

    print("DESKEY 1 : "+ t_1+"\nDESKEY 2 : "+t_2+"\nDESKEY 3 : "+t_3)
    
    #Bytes对象16进制转换
    t_1 = binascii.a2b_hex(t_1)
    t_2 = binascii.a2b_hex(t_2)
    t_3 = binascii.a2b_hex(t_3)

    LM_R1 = DesEncrypt(Challenge,t_1)
    LM_R2 = DesEncrypt(Challenge,t_2)
    LM_R3 = DesEncrypt(Challenge,t_3)

    print("DesRes 1 : "+ LM_R1.decode() + "\nDesRes 2 : " + LM_R2.decode()+"\nDesRes 3 : " + LM_R3.decode())
    print("Response Result : " + LM_R1.decode()+LM_R2.decode()+LM_R3.decode())