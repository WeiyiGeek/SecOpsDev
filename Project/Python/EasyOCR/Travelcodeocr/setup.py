# -*- coding: utf-8 -*-
# ####################################################################
# Author: WeiyiGeek
# Description: 基于easyocr实现大数据通信行程卡图片识别信息获取-Flask项目。
# Time: 2022年5月25日 17点31分
# Blog: https://www.weiyigeek.top
# Email: master@weiyigeek.top
# Modity: 2022年8月10日 14点53分
# ====================================================================
# 环境依赖与模块安装, 建议 Python 3.8.x 的环境下进行
# pip install flask
# pip install easyocr
# pip install gevent
# pip3 install gevent-websocket
# ====================================================================
# 行程码有绿色、黄色、橙色、红色四种颜色。
# 1、红卡：行程中的中高风险地市将标记为红色字体作提示。
# 2、橙卡：新冠肺炎确诊或疑似患者的密切接触者。
# 3、黄卡：海外国家和地区。
# 4、绿卡：其他地区。行程卡结果包含在前14天内到访的国家（地区）与停留4小时以上的国内城市。色卡仅对到访地作提醒，不关联健康状况。
# #####################################################################

import os
import cv2
import re
import glob
import json
import easyocr
import logging
import collections
import argparse
from flask import Flask, jsonify, request,render_template
from datetime import datetime
from werkzeug.utils import secure_filename
import numpy as np
from gevent import pywsgi
from mylogger import logger
from logging.handlers import RotatingFileHandler
from geventwebsocket.handler import WebSocketHandler

app = Flask(__name__)

# 运行参数
parser = argparse.ArgumentParser(description="本程序利用easyocr进行图像文字识别，实现行程码与健康码的识别",prog='Easyocr')
parser.add_argument('--rundir',dest="rundir", type=str, help="指定程序运行目录", required=False, default="./")
parser.add_argument('--imgdir',dest="imgdir", type=str, help="指定图像存放目录", required=False, default="./img")
parser.add_argument('--gpu',dest="gpu", type=bool, help="指定是否使用GPU执行计算(缺省: Flase)", required=False, default=False)
parser.add_argument('--ip',dest="ip", type=str, help="指定服务监听网卡(缺省: 0.0.0.0)", required=False, default="0.0.0.0")
parser.add_argument('--port',dest="port", type=int, help="指定服务的端口(缺省: 8000)", required=False, default=8000)
args = parser.parse_args()

# 常量定义
RUNDIR = args.rundir
IMGDIR = args.imgdir
codeDict = {"green": "绿码", "yellow": "黄码", "red": "红码", "other": "暂时无法确认"}
colorDict = {"red": "红色", "red1": "红色", "orange": "橙色", "yellow": "黄色", "green": "绿色"}

def getColorList():
  """
  函数说明: 定义字典存放 HSV 颜色分量上下限 (HSV-RGB)
  例如：{颜色: [min分量, max分量]}
      {'red': [array([160, 43, 46]), array([179, 255, 255])]}
  返回值: 专门的容器数据类型，提供Python通用内置容器、dict、list、set和tuple的替代品。
  """
  dict = collections.defaultdict(list)

  # 红色
  lower_red = np.array([156, 43, 46])
  upper_red = np.array([180, 255, 255])
  color_list = []
  color_list.append(lower_red)
  color_list.append(upper_red)
  dict['red']=color_list
 
  # 红色2
  lower_red = np.array([0, 43, 46])
  upper_red = np.array([10, 255, 255])
  color_list = []
  color_list.append(lower_red)
  color_list.append(upper_red)
  dict['red2'] = color_list

  # 橙色
  lower_orange = np.array([11, 43, 46])
  upper_orange = np.array([25, 255, 255])
  color_list = []
  color_list.append(lower_orange)
  color_list.append(upper_orange)
  dict['orange'] = color_list
 
  # 黄色
  lower_yellow = np.array([26, 43, 46])
  upper_yellow = np.array([34, 255, 255])
  color_list = []
  color_list.append(lower_yellow)
  color_list.append(upper_yellow)
  dict['yellow'] = color_list

  # 绿色
  lower_green = np.array([35, 43, 46])
  upper_green = np.array([77, 255, 255])
  color_list = []
  color_list.append(lower_green)
  color_list.append(upper_green)
  dict['green'] = color_list

  return dict

def getTravelcodeColor(img_np):
  """
  函数说明: 利用阈值返回行程码主页颜色
  参数值: cv2.imread() 读取的图像对象(np数组)
  返回值: 行程卡颜色{红、橙、绿}
  """
  hsv = cv2.cvtColor(img_np, cv2.COLOR_BGR2HSV)
  maxsum = -100
  color = None
  color_dict = getColorList()
  for d in color_dict:
    mask = cv2.inRange(hsv,color_dict[d][0],color_dict[d][1])
    # cv2.imwrite(os.path.join(os.path.abspath(os.curdir),"img",d+'.jpg')  ,mask)
    binary = cv2.threshold(mask, 127, 255, cv2.THRESH_BINARY)[1]
    binary = cv2.dilate(binary,None,iterations=2)
    cnts, hiera = cv2.findContours(binary.copy(),cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE)
    sum = 0
    for c in cnts:
      sum+=cv2.contourArea(c)
    if sum > maxsum :
      maxsum = sum
      color = d

  return colorDict[color]

def health_filter(file_path, img_np ,text_str):
  """
  函数说明: ocr识别的健康码
  参数值：字符串,文件名称
  返回值：有效信息组成的字典
  """
  # 健康码字段
  try:
    result_dic = None
    for i in codeDict:
      if (text_str.find(codeDict[i]) > 0) :
        result_dic = {"code": 200,"msg" : "成功获取健康码图片数据为有健康码状态.", "data" :{"file": file_path ,"type": codeDict[i]}}
        if ( i == "other" ):
          result_dic = {"code": 200,"msg" : "成功获取健康码图片数据为无码.", "data" :{"file": file_path ,"type": "无码"}}
        break
      else:
        result_dic = {"code": 0,"msg" : "识别健康码图片数据未在字典范围内.", "data" :{"file": file_path ,"type": "未知"}}
    return result_dic
  except Exception as _:
    # healthcode = getTravelcodeColor(img_np)  # 文字无法识别时采用图片颜色识别
    # print("[*] Get Photo Color = ",healthcode)
    result_dic = {"code": 0,"msg" : "识别健康码图片数据失败.", "data" :{"file": file_path ,"type": "未知"}}
    return result_dic
    
def getHealthCodeInfo(filename, img_np):
  """
  函数说明: 获取健康码信息
  参数值：文件名称, 图像作为 numpy 数组进行opencv传递
  返回值：返回以JSON字符串格式过滤后结果
  """
  # 灰度处理
  # img_gray = cv2.cvtColor(img_np, cv2.COLOR_BGR2GRAY)
  # 阈值二进制 - > 127 设置为255(白)，否则0(黑) -> 淡白得更白,淡黑更黑
  # _,img_thresh = cv2.threshold(img_gray,176,255,cv2.THRESH_BINARY)
  # 图像 OCR 识别
  text = reader.readtext(img_np, detail=0, batch_size=64) 
  result_dic = health_filter(filename, img_np, "".join(text))
  return result_dic
  

def travel_filter(file_path,img_np,text_str):
  """
  函数说明: ocr识别的行程码
  参数值：字符串,文件名称
  返回值：有效信息组成的字典
  """
  # 健康码字段
  try:
    re_healthcode = re.compile('请收下(.{,2})行程卡')
    healthcode = re_healthcode.findall(text_str)[0]
  except Exception as _:
    healthcode = getTravelcodeColor(img_np)  # 文字无法识别时采用图片颜色识别
    print("[*] Get Photo Color = ",healthcode)

  # 电话字段
  re_phone = re.compile('[0-9]{3}\*{4}[0-9]{4}')
  phone_str = re_phone.findall(text_str)[0]

  # 日期字段
  re_data = re.compile('2022\.[0-1][0-9]\.[0-3][0-9]')
  data_str = re_data.findall(text_str)[0]

  # 时间字段
  re_time = re.compile('[0-9][0-9]:[0-9][0-9]:[0-9][0-9]')
  time_str = re_time.findall(text_str)[0]

  # 地区城市字段
  citys_re = re.compile('到达或途经:(.+)结果包含')
  citys_str = citys_re.findall(text_str)[0].strip().split('(')[0]

  result_dic = {"code": 200,"msg" : "成功获取行程码数据.", "data" :{"file": file_path ,"type": healthcode, "phone": phone_str, "date": data_str, "time": time_str, "travel": citys_str}}
  return result_dic


def getTravelCodeInfo(filename, img_np):
  """
  函数说明: 返回以JSON字符串格式过滤后结果
  参数值：文件名称,图像作为numpy数组进行opencv传递
  返回值：JSON字符串格式
  """
  # 灰度处理
  img_gray = cv2.cvtColor(img_np, cv2.COLOR_BGR2GRAY)
  # 阈值二进制 - > 127 设置为255(白)，否则0(黑) -> 淡白得更白,淡黑更黑
  _,img_thresh = cv2.threshold(img_gray,176,255,cv2.THRESH_BINARY)
  # 图像 OCR 识别
  text = reader.readtext(img_thresh, detail=0, batch_size=64)
  result_dic = travel_filter(filename, img_np, "".join(text))
  return result_dic

# Flask 路由 - 首页
@app.route('/')
@app.route('/index')
def Index():
  return "<h4 style='text-algin:center'>https://www.weiyigeek.top</h4><script>window.location.href='https://www.weiyigeek.top'</script> <br/><h4 style='text-algin:center'>/api/v1/ocr/health?action=jkm&file=20220520/test.png <br> /api/v1/ocr/health?action=xcm&file=20220520/test.png </h4>"

# Flask 路由
@app.route('/api/v1/ocr/health',methods=["GET"])
def Travelcodeocr():
  """
  请求路径: /api/v1/ocr/health
  请求参数: (/api/v1/ocr/health?action=['jkm','xcm']&file=20220520/test.png, /tools/ocr?dir=20220520)
  """
  action = request.args.get("action")
  filename = request.args.get("file")
  dirname = request.args.get("dir")
  if (action and filename):
    img_path = os.path.join(IMGDIR, filename)
    if (os.path.exists(img_path)):
      # 打印路径
      log.info("图像路径: "+ img_path)
      img_np = cv2.imread(img_path)
      try:
        if (action == "jkm"):
          result_dic_succ = getHealthCodeInfo(filename,img_np)
        else:
          result_dic_succ = getTravelCodeInfo(filename,img_np)
      except Exception as err:
        result_dic_err = {"code": 0,"msg" : "图像数据获取异常, 请调用第三方接口识别.","data" :{"action": action,"file": filename ,"type": "未知"}}  
        log.error(str(err) + "-" + str(result_dic_err))
        return json.dumps(result_dic_err, ensure_ascii=False).encode('utf-8'), 200, {"Content-Type":"application/json"} 

      log.info(result_dic_succ)
      return json.dumps(result_dic_succ, ensure_ascii=False).encode('utf-8'), 200, {"Content-Type":"application/json"}
    else:
      result_dic_err={"code": 0,"msg": "图像数据获取异常, 文件"+filename+"或者路径不对, 请检查."}
      log.error(str(result_dic_err))
      return json.dumps(result_dic_err, ensure_ascii=False).encode('utf-8'), 200, {"Content-Type":"application/json"}

  elif (action and dirname and os.path.join(IMGDIR, dirname)):
    result_dic_all = []
    result_dic_err = []
    img_path_all =  glob.iglob(os.path.join(os.path.join(IMGDIR,dirname)+"/*.[p|j]*g"))   # 正则匹配 png|jpg|jpeg 后缀的后缀,返回的是迭代器。
    for img_path in img_path_all:
      img_np = cv2.imread(img_path)
      try:
        result_dic_succ = getTravelCodeInfo(os.path.join(dirname,os.path.basename(img_path)),img_np)
      except Exception as err:
        print("\033[31m"+ img_path + " -->> " + str(err) + "\033[0m") # 输出识别错误的图像
        result_dic_err.append(img_path)
        continue

      # 成功则加入到List列表中
      result_dic_all.append(result_dic_succ)

    res_succ_json=json.dumps(result_dic_all, ensure_ascii=False)
    res_err_json=json.dumps(result_dic_err, ensure_ascii=False)

    with open(os.path.join(IMGDIR, dirname, dirname + "-succ.json"),'w') as succ:
      succ.write(res_succ_json)
    with open(os.path.join(IMGDIR, dirname,  dirname + "-err.json"),'w') as error:
      error.write(res_err_json)

    return res_succ_json.encode('utf-8'), 200, {"Content-Type":"application/json"}
  else:
    return jsonify({"code": "0","msg": "请求参数有误!"})


# Flask 路由 - /tools/upload/ocr
@app.route('/tools/upload/ocr',methods=["GET","POST"])
def TravelcodeUploadocr():
  if request.method == 'POST':
    unix = datetime.now().strftime('%Y%m%d-%H%M%S%f')
    f = request.files['file']
    if (f.mimetype == 'image/jpeg' or f.mimetype == 'image/png'):
      filedate = unix.split("-")[0]
      filesuffix = f.mimetype.split("/")[-1]
      uploadDir = os.path.join('img',filedate)

      # 判断上传文件目录是否存在
      if (not os.path.exists(uploadDir)):
        os.makedirs(uploadDir)
      # 图片路径拼接与写入图片
      img_path = os.path.join(uploadDir,secure_filename(unix+"."+filesuffix)) 
      f.save(img_path) 
      # log.info("上传路径:" + img_path)

      # 判断上传文件是否存在
      if (os.path.exists(img_path)):
        img_np = cv2.imread(img_path)
        try:
          result_dic_succ = getTravelCodeInfo(os.path.join(filedate,os.path.basename(img_path)),img_np)
        except Exception as err:
          result_dic_err = {"code": 0,"msg" : "图像数据获取异常, 请调用第三方接口识别.","data" :{"action": "upload","img_path": img_path ,"type": "未知"}}  
          log.error(str(err) + "-" + str(result_dic_err))
          return json.dumps(result_dic_err, ensure_ascii=False).encode('utf-8'), 200, {"Content-Type":"application/json"} 

        log.info(str(result_dic_succ))
        return json.dumps(result_dic_succ, ensure_ascii=False).encode('utf-8'), 200, {"Content-Type":"application/json"}
      else:
        result_dic_err={"code": 0,"msg": "图像数据获取异常, 文件"+img_path+"或者路径不对, 请检查."}
        log.error(str(result_dic_err))
        return json.dumps(result_dic_err, ensure_ascii=False).encode('utf-8'), 200, {"Content-Type":"application/json"}
    else:
      return jsonify({"status": "err","msg": "不能上传除 jpg 与 png 格式以外的图片"})
  else:
    return render_template('index.html')


# 程序入口
if __name__ == '__main__':
  log = logger("app")
  # 全局设置日志的记录等级，调试INFO级
  logging.basicConfig(level=logging.INFO) 
  # 创建日志记录器，指明日志保存的路径、每个日志文件的最大大小、保存的日志文件个数上限 (100 兆)
  file_log_handler = RotatingFileHandler("log/console.log", maxBytes=1024 * 1024 * 100, backupCount=10, encoding="utf-8")
  # 创建日志记录的格式 日志等级 输入日志信息的文件名 行数 日志信息
  formatter = logging.Formatter('%(levelname)s - %(message)s')
  # 为刚创建的日志记录器设置日志记录格式
  file_log_handler.setFormatter(formatter)
  # 为全局的日志工具对象（flask app使用的）添加日志记录器
  logging.getLogger().addHandler(file_log_handler)

  # try:
  #   RUNDIR = sys.argv[1]
  #   IMGDIR = sys.argv[2]
  # except Exception as e:
  #   print("[*] Uage:"+ sys.argv[0] + " RUNDIR IMGDIR")
  #   print("[*] Default:"+ sys.argv[0] + " ./ ./img" + "\n" )
  #   RUNDIR = os.path.abspath(os.curdir)
  #   IMGDIR = os.path.join(RUNDIR,"img")
  # finally:
  #   if os.path.exists(RUNDIR):
  #     RUNDIR = os.path.abspath(os.curdir)
  #   if os.path.exists(IMGDIR):
  #     IMGDIR = os.path.join(RUNDIR,"img")

  # 使用easyocr模块中的Reader方法, 设置识别中英文两种语言
  reader = easyocr.Reader(['ch_sim', 'en'], gpu=args.gpu, detector=True, recognizer=True) 
  # 使用原生app运行web(单线程)
  # app.run(host='0.0.0.0', port=8000, debug=False)
  # 使用WSGIServer多线程(实际上是异步)
  server = pywsgi.WSGIServer((args.ip, args.port), app, handler_class=WebSocketHandler)
  server.serve_forever()
