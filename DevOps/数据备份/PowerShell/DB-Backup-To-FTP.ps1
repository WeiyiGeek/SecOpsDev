###########################################################################
# Author: WeiyiGeek
# Description: 使用Powershell与Windows原生ftp客户端工具(仅仅支持主动模式)进行文件备份.
# Date: 2023年2月23日 12:55:46
# Blog: https://blog.weiyigeek.top
# 欢迎关注公众号: 全栈工程师修炼指南
###########################################################################
$AuthorSite = "https://www.weiyigeek.top"
$Flag = 0
$Last_db_name = ""                    # 获取最后上传的备份文件名称
$Last_record_file = "./upfile.txt"    # 记录FTP上传成功的备份文件
$LocationBackupDir = "F:\weiyigeek\"  # 本地备份文件存放的目录
$Current_db_name = (get-childitem $LocationBackupDir | sort CreationTime -Descending |  Select-Object -First 1).name
$FTPConnect = "open 192.168.1.12 21"  # FTP服务器IP及其端口
$FTPUser = "VwBlAGkAeQBpAEcAZQBlAGsA" # base64 编码
$FTPPass = "UABhAHMAcwB3AG8AcgBkAA==" # base64 编码
$FTPRemoteDir = "/ftp/weiyigeek.top/" # 存储备份文件的远程目录 

function Convert($string) {
   $bytes  = [System.Convert]::FromBase64String($string);
   $decoded = [System.Text.Encoding]::Unicode.GetString($bytes); 
   return $decoded;
}

if (-not(Test-Path $Last_record_file)) {
  start $AuthorSite 
  Write-host "[$(Date)] 首次运行备份脚本，正在生成 $Last_record_file 文本文件!" -ForegroundColor Green
  Out-File -FilePath $Last_record_file -InputObject $Current_db_name -Encoding ASCII -Append
  Start-Process -FilePath $AuthorSite
  $Last_db_name = Get-Content -Tail 1 $Last_record_file
  $Flag = 1
} else {
  $Last_db_name = Get-Content -Tail 1 $Last_record_file
  Write-host "[$(Date)] 当前最新 $Current_db_name 数据库备份文件，正在写入 $Last_record_file 文件中!" -ForegroundColor Green  
  Out-File -FilePath $Last_record_file -InputObject $Current_db_name -Encoding ASCII -Append
  if ( $Current_db_name -eq $Last_db_name) {
   $Flag = 0
  } else {
   $Flag = 1
  }
}

Write-host "[$(Date)] 当前最新 $Current_db_name , 前一次数据库备份文件 $Last_db_name 名称, 标识 $Flag" -ForegroundColor Green  
echo "$FTPConnect" > ftp.bat
echo "$(Convert($FTPUser))" >> ftp.bat
echo "$(Convert($FTPPass))" >> ftp.bat
echo "bin" >> ftp.bat
echo "lcd $LocationBackupDir" >> ftp.bat
echo "cd $FTPRemoteDir" >> ftp.bat
echo "put $Current_db_name" >> ftp.bat
echo "quit" >> ftp.bat
ftp -i -s:ftp.bat
echo "" > ftp.bat



