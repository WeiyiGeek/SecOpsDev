// # @Filename: 2.ls
// # @Author: WeiyiGeek
// # @Description: 网页站点全屏截取并生成pdf与png两种格式
// # @Create Time: 2023年1月11日 12:39:06
// # @Last Modified time: 2023年1月11日 12:39:09
// # @E-mail: master@weiyigeek.top
// # @Blog: https://www.weiyigeek.top
// # @wechat: WeiyiGeeker
// # @Github: https://github.com/WeiyiGeek/SecOpsDev/



var page = require('webpage').create(),
system = require('system'),
url,outputType,size,nowTime;

if( system.args.length == 1 ){  
  console.log("Usage: screen-capture.js url [file.png|file.ph pdf] [paperwidth*paperheight|paperformat] [zoom]")
  console.log('  paper (pdf output) examples: "5in*7.5in", "10cm*20cm", "A4", "Letter"');
  console.log('  image (png/jpg output) examples: "1920px" entire page, window width 1920px');
  console.log('                                   "800px*600px" window, clipped to 800x600');
  phantom.exit();  
}else{  
  url = system.args[1];
  outputType = system.args[2];
 
  nowTime = Date.now();

  // 默认宽度与高度
  pageWidth = 1024;
  pageHeight = 720;
  page.viewportSize = { width: pageWidth, height: pageHeight };

  if (system.args.length > 3 && outputType.substr(-4) === "pdf") {
    size = system.args[3].split('*');
    page.paperSize = size.length === 2 ? { width: size[0], height: size[1], margin: '0px' }
                                       : { format: 'A4', orientation: 'portrait', margin: '1cm' };
  } else if (system.args.length > 3 && system.args[3].substr(-2) === "px") {
      size = system.args[3].split('*');
      if (size.length === 2) {
          pageWidth = parseInt(size[0], 10);
          pageHeight = parseInt(size[1], 10);
          page.viewportSize = { width: pageWidth, height: pageHeight };
          // page.clipRect = { top: 0, left: 0, width: pageWidth, height: pageHeight };
          page.clipRect = { top: 0, left: 0, width: pageWidth };
      } else {
          console.log("size:", system.args[3]);
          pageWidth = parseInt(system.args[3], 10);
          pageHeight = parseInt(pageWidth * 3/4, 10); // it's as good an assumption as any
          console.log ("pageHeight:",pageHeight);
          page.viewportSize = { width: pageWidth, height: pageHeight };
      } 
  }
  
  if (system.args.length > 4) {
    page.zoomFactor = system.args[4];
  }

  // 站点头
  page.settings.userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:108.0) Gecko/20100101 Firefox/108.0";

  // 站点请求
  page.open(url, function (status){  
    console.log(status)
  if (status !== "success"){  
    console.log('FAIL to load the address');  
    phantom.exit();  
  } else {
    // 请求站点目标页面上下文环境
    page.evaluate(function(){ 
      //滚动到底部  
      window.scrollTo(0,document.body.scrollHeight);
    
      // DOM 操作给所有A标签加上一个边框
      window.setTimeout(function(){  
        var plist = document.querySelectorAll("a");  
        var len = plist.length;  
        while(len)  
        {  
            len--;  
            var el = plist[len];  
            el.style.border = "1px solid red";  
        }  
      }, 2000);  
  });  
    
    window.setTimeout(function (){  
      // 在本地生成截图以及PDF
      // filename = url.split("//")[1]+"_"+nowTime+"."+outputType;
      page.render(outputType);
      console.log(outputType);
      // 打印html内容
      // console.log(page.content); 
      phantom.exit();  
    }, 3000);      
    };  
  }); 
}  