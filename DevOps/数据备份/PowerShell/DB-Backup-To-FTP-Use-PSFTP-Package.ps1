##############################################################################################################
# Author： WeiyiGeek
# Description：在Powershell中使用PSFTP模块包快速实现FTP连接与文件上传
# Date： 2023年2月23日 12:55:46
# Blog： https://blog.weiyigeek.top
# Wechat：WeiyiGeeker
# 欢迎关注公众号: 全栈工程师修炼指南
##############################################################################################################
$AuthorSite = "https://www.weiyigeek.top"
$Flag = 0
$Last_db_name = ""                       # 获取最后上传的备份文件名称
$Last_record_file = "./upload.txt"       # 记录FTP上传成功的备份文件
$LocationBackupDir = "F:\WeiyiGeek"  # 本地备份目录
$Current_db_name = (get-childitem $LocationBackupDir | sort CreationTime -Descending |  Select-Object -First 1).name # 获取最新生成的备份文件
$FTPConnect = "ftp://10.20.176.215:30021"  # FTP 服务器链接字符串
$FTPUser = "dwBlAGkAeQBpAGcAZQBlAGsA"      # base64 编码
$FTPPass = "cABhAHMAcwB3AG8AcgBkAA=="      # base64 编码
$FTPDir = "/weiyigeek"

# 依赖检查
function CheckRequipment() {
  if (-not(Get-Module -ListAvailable PSFTP)) {
   Write-host "[$(Date)] 当前系统中不存在 PSFTP 模块，请在管理员权限下运行 Install-Module -Name PSFTP 命令" -ForegroundColor Red  
   $res=$(Read-Host "[$(Date)] 是否执行安装PSFTP模块命令[Y/N]?")
   if ( $res -eq "Y" ) {
    Install-Module -Name PSFTP 
   } else {
    Write-host "[$(Date)] 请手动在管理员权限下运行 Install-Module -Name PSFTP 命令" -ForegroundColor Red  
    Exit -1
   }
  } else {
   Write-host "[$(Date)] 脚本依赖检测通过...." -ForegroundColor Green  
  }
}

# 编码转换
function Convert($string) {
   $bytes  = [System.Convert]::FromBase64String($string);
   $decoded = [System.Text.Encoding]::Unicode.GetString($bytes); 
   return $decoded;
}

# 上传函数
function Upload($file_name,$ftp_user,$ftp_pass) {
   # 创建连接票据
   $FTPCre = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ftp_user, $ftp_pass

   # 设置ftp服务器连接&并返回状态
   (Set-FTPConnection -Credentials $FTPCre -Server $FTPConnect -UsePassive).WelcomeMessage

   # 上传指定文件
   try {
       Send-FTPItem -LocalPath $LocationBackupDir\${file_name} -Path $FTPDir -Overwrite
       Write-Host "[$(Date)] Upload Status: $($response.StatusDescription)`nUpload File $FTPDir/$file_name successful! " -ForegroundColor Green  
    } catch {
        Write-Host "[$(Date)] Upload File $FTPConnectRemoteDir/$db_name Faild!" -ForegroundColor Red
    } finally {
       Exit-PSSession 
    }
}

# 函数入口
function main () {
    if (-not(Test-Path $Last_record_file)) {
        start $AuthorSite
        CheckRequipment
        Write-host "[$(Date)] 首次运行备份脚本，正在生成 $Last_record_file 文本文件!" -ForegroundColor Green
        Out-File -FilePath $Last_record_file -InputObject $Current_db_name -Encoding ASCII -Append
        $Last_db_name = Get-Content -Tail 1 $Last_record_file
        $Flag = 1
    } else {
        $Last_db_name = Get-Content -Tail 1 $Last_record_file
        if ( "$Current_db_name" -eq "$Last_db_name" ) {
        $Flag = 0
        } else {
        $Flag = 1
        }
    }

    Out-File -FilePath ./logs.txt -InputObject "[$(Date)] 程序执行，当前上传标识 $Flag . " -Encoding utf8 -Append

    if ( $Flag -ne 0 ) {
        Write-host "[$(Date)] 当前数据库备份文件 $Current_db_name ，写入 $Last_record_file 文件中!" -ForegroundColor Green  
        Out-File -FilePath $Last_record_file -InputObject $Current_db_name -Encoding ASCII -Append
        $logs = "[$(Date)] 当前数据库备份文件 $Current_db_name , 上次数据库备份文件 $Last_db_name 名称, 上传标识 $Flag ."
        Write-host $logs -ForegroundColor Green  
        Out-File -FilePath ./logs.txt -InputObject $logs -Encoding utf8 -Append
        $FTPPassword = ConvertTo-SecureString -String $(Convert($FTPPass)) -AsPlainText -Force
        Upload -file_name $Current_db_name -ftp_user $(Convert("$FTPUser ")) -ftp_pass $FTPPassword
    }
}

main

