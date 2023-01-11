// # @Filename: hello-page-automation.js
// # @Author: WeiyiGeek
// # @Description: 使用标准DOM API或jQuery等常用库访问网页并提取信息
// # @Create Time: 2023年1月11日 12:39:06
// # @Last Modified time: 2023年1月11日 12:39:09
// # @E-mail: master@weiyigeek.top
// # @Blog: https://www.weiyigeek.top
// # @wechat: WeiyiGeeker
// # @Github: https://github.com/WeiyiGeek/SecOpsDev/

// DOM 操作,示例演示如何读取跳转后class为post-card-title的元素的textContent属性
// 可以通过创建网页对象来加载、分析和呈现网页
var page = require('webpage').create(),
system = require('system'),
url,textContent;

// 检查传入命令行参数数量
if (system.args.length === 1 ) {
  console.log('Usage: hello-PhantomJS.js [some URL]');
  phantom.exit();
} else {
  // 获取命令行传入的参数
  url = system.args[1];
}

// 设置 请求的UserAgent
console.log('The default user agent is ' + page.settings.userAgent);
page.settings.userAgent = 'WeiyiGeekAgent';

// 请求访问站点
page.open(url, function(status) {
  console.log("----------------- 分隔线 -------------------------")
  console.log("Status: " + status);  
  if (status !== 'success') {
    console.log('Unable to access site : ' + url);
  } else { 
  // 渲染延迟200ms时间进行截图，等待网站渲染完成
  setTimeout(function() {
    // 使用evaluate获取JS后Dom文档对象
    textContent = page.evaluate(function() {
      return document.getElementsByClassName("post-card-title")[0].textContent ;
    });
    console.log('textContent ：' + textContent );
    // console.log('page plainText : ' + page.plainText);
    page.render(url.split("//")[1]+'.png');
    // 终止执行
    phantom.exit();
  }, 2000);

  console.log('page Title : ' + page.title);
  console.log('page Url : ' + page.url);
  console.log('page Cookies :' + page.cookies[1].name + " : " + page.cookies[1].value);
  console.log('page ZoomFactor : ' + page.zoomFactor);
  console.log('page OfflineStoragePath : ' + page.offlineStoragePath);
  console.log('page LibraryPath : ' + page.libraryPath);
    
  // 从1.6版开始，您还可以使用page.includeJs将jQuery包含到页面中，如下所示：
  page.includeJs("https://blog.weiyigeek.top/js/jquery/2.1.0-jquery.min.js?v=1.6.6", function() {
    var Title =  page.evaluate(function() {
       // 模拟点击请求
      $("a")[10].click();
      // document.getElementsByTagName('a')[10].click()
       return document.title;
     });
    console.log("Blog Title : " + Title);
  });
  }
});