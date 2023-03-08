## 使用Powershell将数据备份文件自动上传到FTP服务器
参考文章: https://blog.weiyigeek.top/2023/3-7-720.html

在下述实践中，我们可以使用三种方式进行数据文件上传到FTP服务器中。
- 方式1.使用Powershell与Windows原生ftp客户端工具(仅仅支持主动模式)进行文件备份.
> 对应脚本：DB-Backup-To-FTP.ps1

- 方式2.使用Powershell中.NET的内置的FTP操作类 `System.Net.FtpWebRequest` 连接ftp服务器并进行备份文件上传.
> 对应脚本：DB-Backup-To-FTP-Use-Net.FtpWebRequest.ps1

- 方式3.使用Powershell的PSFTP模块包连接ftp服务器并进行备份文件上传。
> 对应脚本：DB-Backup-To-FTP-Use-PSFTP-Package.ps1 

![WeiyiGeek.PSFTP模块实践自动上传备份文件代码图](https://img.weiyigeek.top/2023/1/20230308094016.png)

温馨提示: 若脚本地址失效，请在【全栈工程师修炼指南】公众号回复 PowerShell-FTP 或者 10000 获取最新PowerShell脚本地址。
注意提示: 在中文Windows下执行脚本默认为GBK，若是乱码请转为GBK或者其他编码模式。
