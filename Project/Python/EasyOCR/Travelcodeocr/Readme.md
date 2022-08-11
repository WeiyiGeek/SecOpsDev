## 基于easyocr实现大数据通信行程卡图片识别信息获取-Flask项目

**环境依赖与模块安装**

```bash
pip install flask
pip install easyocr
pip install gevent
pip install gevent-websocket
```

**脚本启动**
```python
python .\setup.py
  # Using CPU. Note: This module is much faster with a GPU.
  # * Serving Flask app 'index' (lazy loading)
  # * Environment: production
  #   WARNING: This is a development server. Do not use it in a production deployment.
  #   Use a production WSGI server instead.
  # * Debug mode: on
  # * Running on all addresses (0.0.0.0)
  #   WARNING: This is a development server. Do not use it in a production deployment.
  # * Running on http://127.0.0.1:8000
  # * Running on http://10.20.172.106:8000 (Press CTRL+C to quit)
  # * Restarting with stat
  # Using CPU. Note: This module is much faster with a GPU.
  # * Debugger is active!
  # * Debugger PIN: 115-313-307
```

**实践参考**

- B站专栏 : https://www.bilibili.com/read/cv16911816

- 博客文章 ：https://blog.weiyigeek.top/2022/5-8-658.html



**使用示例**

当前版本:

```bash
- # 指定健康码图片文件
> http://127.0.0.1:8000/api/v1/ocr/health?action=jkm&file=20220809/118d180d2dc540109d9ab2e22b1529ea.jpg
{"code": 200, "msg": "成功获取健康码图片数据为有健康码状态.", "data": {"file": "20220809/118d180d2dc540109d9ab2e22b1529ea.jpg", "type": "黄码"}}

- # 指定行程码图片文件
> http://127.0.0.1:8000/api/v1/ocr/health?action=xcm&file=20220530/001c35d7ac9844e78c15783bf7fda815.png
{"code": 200, "msg": "成功获取行程码数据.", "data": {"file": "20220809/001c35d7ac9844e78c15783bf7fda815.png", "type": "绿色", "phone": "153****2031", "date": "2022.08.09", "time": "08:34:10", "travel": "重庆市"}}

- # 批量扫描目录中的行程码图片文件
> http://127.0.0.1:8000/tools/ocr?dir=20220530
- # 上传行程码识别
> http://127.0.0.1:8000/tools/upload/ocr
```

V1 版本

```bash
- # 指定行程码图片文件
> http://127.0.0.1:8000/tools/ocr?file=20220530/0a1e948e90964d42b435d63c9f0aa268.png
- # 批量扫描目录中的行程码图片文件
> http://127.0.0.1:8000/tools/ocr?dir=20220530
- # 上传行程码识别
> http://127.0.0.1:8000/tools/upload/ocr
```

**执行结果**

当前最新版本:

![image-20220811211957874](./img/image-20220811211957874.png)

V1 版本

![](./img/image-20220530215301119.png)


