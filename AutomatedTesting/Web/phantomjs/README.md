## 前言简述


**什么是PhantomJS?\**

\> Phantomjs(`/ˈfæntəm/js`) 是一个基于WebKit库的无头（没有显示界面）的JavaScript API，即像在web浏览器上运行一样，所以标准的DOM脚本和CSS选择器工作正常，用于自动化Web浏览器操作，是一个免费开源的轻量级服务器解决方案。

\> 它可以在Windows、macOS、Linux和FreeBSD上运行, 并且使用QtWebKit作为后端，它为各种web标准提供了快速的本地支持：DOM处理、CSS选择器、JSON、画布和SVG。



***\*PhantomJS有什么用?\****

\> 它可以用来测试动态内容, 比如 AJAX内容、截屏，以及转换为PDF和原型图，它也可以执行跨浏览器的JavaScript测试，可以模拟网络延迟、网页截屏、页面访问自动化以及捕获网络脚本的错误和警告等。

\> 它不仅是个隐形的浏览器, 还提供了诸如CSS选择器、支持Web标准、DOM操作、JSON、HTML5、Canvas、SVG等，同时也提供了处理文件I/O的操作，从而使你可以向操作系统读写文件等。

\> 简单的说, PhantomJS 适合执行各种页面自动化监控、测试任务等。



**示例演示:**

主要实现的功能是利用Shell脚本以及crontab定时任务以及 PhantomJS 来监控网站首页的变化，并以截图的方式通知给企业微信对应运维群，及时了解网站运行安全，防止网站主页被黑、被劫持的风险。

此处我是在CentOS7中实现的，安装方法请参考我博客文章【https://blog.weiyigeek.top/2020/6-29-264.html】前面章节

脚本执行及其结果: 
```bash
# 代码执行
chmod +x /1.WebMonitorScreenCapture.sh
./1.WebMonitorScreenCapture.sh

cd /var/log/WebScreenCapture/www.baidu.com
ls /var/log/WebScreenCapture/www.com
20230111172153-index.html  20230111172153-index.html.png  20230111173604-index.html  data.json  exception.log  index.html  text.json
```
![WeiyiGeek.PhantomJS网站监控预警图](https://img.weiyigeek.top/2022/10/20230111172323.png)




\* 官方地址: http://phantomjs.org/

\* PhantomJS GitHub：https://github.com/ariya/phantomjs/

\* PhantomJS官方API：http://phantomjs.org/api/

\* PhantomJS官方示例：http://phantomjs.org/examples/

\* 实践演示脚本示例: https://github.com/WeiyiGeek/SecOpsDev/AutomatedTesting/Web/phantomjs 