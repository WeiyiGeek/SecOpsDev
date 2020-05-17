##
## @Desc:Java_Web开发环境部署脚本
## @Author: WeiyiGeek
## @CreateTime: 2020年4月1日 10点11分
##


## 依赖文件
## 1.apache-maven-3.6.3-bin
## 2.eclipse-jee-2019-12-R-win32-x86_64.zip
## 3.apache-tomcat-9.0.31.zip

## 绑定参数说明:注意必须放在脚本最上面否则报错
## 1.InstallPath 软件安装路径
## 2.TomcatPort 测试端口防火墙通讯
## 3.JdkPath 安装目录

[CmdletBinding()]
Param (
  [string] $InstallPath = ".",
  [Int32] $TomcatPort = 8080,
  [string] $JdkPath = "C:\Program Files\Java\jdk1.8.0_221"
)

$flag = Test-Path -Path $InstallPath
if(!$flag){
    Write-Host "1.正在建立 $InstallPath " -ForegroundColor Green
    New-Item -ItemType Directory -Path $Installpath -Force
    mkdir $InstallPath\repository
}

Write-Host "2.正在解压安装到 $InstallPath 目录 " -ForegroundColor Green
if(!(Test-Path "$InstallPath/apache-maven-3.6.3-bin")) {
   Expand-Archive -Path "./apache-maven-3.6.3-bin.zip" -DestinationPath $InstallPath -Force
}

if(!(Test-Path "$InstallPath/eclipse")) {
Expand-Archive -Path "./eclipse-jee-2019-12-R-win32-x86_64.zip" -DestinationPath $InstallPath -Force
}
if(!(Test-Path "$InstallPath/apache-tomcat-9.0.31")){
    Expand-Archive -Path "./apache-tomcat-9.0.31.zip" -DestinationPath $InstallPath -Force
}

#if(!(Test-Path "$InstallPath/jeecms-parent")){
#    Expand-Archive -Path "./JEECMSx1.2.0_mysql_src.zip" -DestinationPath $InstallPath -Force
#}


Write-Host "3.正在安装JAVA 依赖JDK : $JdkPath" -ForegroundColor Green
$flag = Test-Path -Path $JdkPath
if (!$flag) {
   Start-Process -Wait ja-FilePath .\jdk-8u221-windows-x64.exe -ArgumentList /s
}else{
   Write-Host "JDK 已经安装无需再次安装" -ForegroundColor Red
}


Write-Host "4.正在设置系统环境 C:\Program Files\Java\jdk1.8.0_221 " -ForegroundColor Green
$Javahome = [System.Environment]::GetEnvironmentVariable("JAVA_HOME","Machine")
if($Javahome -eq $JdkPath ){ 
    Write-Host "Java 运行环境已经设置无需再次设置"  -ForegroundColor Green
} else {
    [System.Environment]::setEnvironmentVariable("JAVA_HOME",$JdkPath,"Machine")
    [System.Environment]::setEnvironmentVariable("CLASSPATH",'.;%JAVA_HOME%\lib\dt.jar;%JAVA_HOME%\lib\tools.jar;', "Machine")
    $systempath = [System.Environment]::GetEnvironmentVariable("PATH","Machine")
    $systempath = $systempath + ";" + ";%JAVA_HOME%\bin;%JAVA_HOME%\jre\bin"
    [System.Environment]::setEnvironmentVariable("PATH",$systempath,"Machine")
    Write-Host "验证 Java 运行环境"  -ForegroundColor Green
    Start-Process cmd -ArgumentList "/k java -version"
}


Write-Host  "5.正在设置防火墙通行规则:Tomcat - $openPort -  ######" -ForegroundColor Green
New-NetFirewallRule -Name "Tomcat-8080" -DisplayName Tomcat-8080-TCP -Direction Inbound -LocalPort $openPort -Protocol TCP -Action Allow

Write-Host "建立Eclipse快捷方式......" -ForegroundColor Green
$shell=New-Object -ComObject WScript.Shell
$desktopPath=[System.Environment]::GetFolderPath('Desktop')
$shortcut=$shell.CreateShortcut("$desktopPath\eclipse.lnk")  
$shortcut.TargetPath="$InstallPath/eclipse/eclipse.exe"
$shortcut.Save()

Write-Host "6.正在验证安装目录......" -ForegroundColor Green
Get-ChildItem -Directory $InstallPath
Start-Process $InstallPath

Write-Host "7.正在打开eclipse.exe......" -ForegroundColor Green
Start-Process $desktopPath/eclipse.lnk
Write-Host "#(1)请修改Maven目录中setting.xml中 localRepository 元素为: $InstallPath/repository"  -ForegroundColor Green
Write-Host "#(2)在Eclipse中导致入 java_web 项目"  -ForegroundColor Green
Write-Host "#(3)在Eclipse中右键 java_web 项目进行Run AS > Maven Install|clear"  -ForegroundColor Green
Write-Host "#(4)生成war路径"  -ForegroundColor Green