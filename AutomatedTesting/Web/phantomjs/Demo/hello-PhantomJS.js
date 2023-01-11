// hello-PhantomJS.js.js
// 参考地址: https://phantomjs.org/quick-start.html

// 输出文字字符到终端
console.log('Hello, world! PhantomJS Demo!');

// 可以通过创建网页对象来加载、分析和呈现网页。
var page = require('webpage').create(),
system = require('system'),
t, url;

// 传入命令行参数数量检测
if (system.args.length === 1 ) {
  console.log('Usage: hello-PhantomJS.js [some URL]');
  // 终止执行
  phantom.exit();
}
// 获取当前时间
t = Date.now();
// 获取命令行传入的参数
url = system.args[1];

// 使用onConsoleMessage回调显示来自网页的任何控制台消息，即站点console输出的信息。
page.onConsoleMessage = function(msg) {
  console.log('Console output : ' + msg);
};

// 请求访问站点
page.open(url, function(status) {
  if (status !== 'success') {
    console.log('FAIL to load the address : ' + url);
  } else {
    t = Date.now() - t;
    // 使用evaluate获取JS后Dom文档对象
    var title = page.evaluate(function() {
      return document.title;
    });
    console.log("----------------- 分隔线 -------------------------")
    console.log("Status: " + status);  
    console.log('Loading ' + url + ', Title ' + title );
    console.log('Loading time ' + t + ' msec');

    // 渲染延迟200ms时间进行截图，等待网站渲染完成
    setTimeout(function() {
      page.render(url.split("//")[1]+'.png');
      // 终止执行
      phantom.exit();
    }, 2000);
  }
});