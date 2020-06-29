# ------------------------------- #
# Author:WeiyiGeek                #
# Ps 数据库备份 & 应用备份           #
# Create: 2020年6月11日 21:34:40  #
# ------------------------------- #    

$TIME=Get-Date
$TIME=$TIME.ToString('yyyy-MM-dd_HHmmss')
$BACKUP_DIR="F:\backup"
$MYSQL_DUMP="F:\backup\mysql-5.7.30-winx64\bin\mysqldump.exe"
$SECURE= "WeiyiGeek_test" | ConvertTo-SecureString -AsPlainText -Force
$CRED = New-Object System.Management.Automation.PSCredential("root",$SECURE) 
$BACKUP_FILENAME="bookstack_${TIME}.tar.gz"

$FLAG=Test-Path -Path "$BACKUP_DIR/SQL"
# 验证备份文件夹是否创建
if (!$FLAG ){
  #New-Item -ItemType Directory -Path $BACKUP_DIR/ -Force
  mkdir "$BACKUP_DIR/SQL"
} 

$FLAG=Test-Path -Path "$BACKUP_DIR/APP"
if ( !$FLAG ){
  mkdir "$BACKUP_DIR/APP"
}

# MySQL数据库备份链接
function dumpMysql {
  param (
    [string] $APP_HOST="",
    [string] $APP_DBNAME="",
    [string] $APP_DBU="",
    [string] $APP_DBP="",
    [int] $APP_PORT=3306
  )

 if([String]::IsNullOrEmpty($APP_HOST) -or [String]::IsNullOrEmpty($APP_DBNAME) -or [String]::IsNullOrEmpty($APP_DBU) -or [String]::IsNullOrEmpty($APP_DBP)){
  Write-Host "# 备份 $APP_DBNAME 数据库错误 "  -ForegroundColor red
  [Environment]::Exit(127)
  } else {
  Write-Host "# 正在备份 $APP_DBNAME 数据库 "  -ForegroundColor Green
  Invoke-Expression "${MYSQL_DUMP} -h 10.20.172.1 -P $APP_PORT --default-character-set=UTF8 -u$APP_DBU -p$APP_DBP -B --databases $APP_DBNAME --hex-blob --result-file=$BACKUP_DIR/SQL/${APP_DBNAME}_${TIME}.sql"
 }
}

# 调用MysqlDump函数执行下载
dumpMysql -APP_HOST 10.20.12.1 -APP_PORT 3306 -APP_DBNAME "snipeit" -APP_DBU "snipeit" -APP_DBP "WeiyiGeek"
dumpMysql -APP_HOST 10.20.12.1 -APP_PORT 3366 -APP_DBNAME "bookstackapp" -APP_DBU "bookstack" -APP_DBP "WeiyiGeek"


# 验证 ssh 模块是否存在
if(Get-Module -ListAvailable -Name Posh-SSH){
  Write-Host "# Posh-SSH 模块已安装"  -ForegroundColor Green
}else{
  Write-Host "# Posh-SSH 模块未安装,正在安装该模块，注意需要管理员权限!"  -ForegroundColor red
  Install-Module -Force Posh-SSH
}

# 执行备份
New-SSHSession -ComputerName 10.20.72.1 -Credential $CRED -AcceptKey
Invoke-SSHCommand -SessionId 0 -Command "tar -zcf $BACKUP_FILENAME /app/bookstack/web/*"

# 执行下载备份
New-SFTPSession -ComputerName 10.20.72.1 -Credential $CRED -AcceptKey
Get-SFTPFile -SessionId 0 -RemoteFile "$BACKUP_FILENAME" -LocalPath "$BACKUP_DIR/APP/"

if((Remove-SSHSession -SessionId 0) -and (Remove-SFTPSession -SessionId 0)){
  Write-Host "# 已关闭SSH与SFTP连接"  -ForegroundColor Green
}else{
  Write-Host "# 关闭连接失败"  -ForegroundColor red
}

# Write-Host "# 正在输出备份数据库路径: $BACKUP_DIR\SQL"  -ForegroundColor Green
# Get-ChildItem F:\backup\SQL\*.sql 
# Write-Host "# 正在输出完整应用备份路径: $BACKUP_DIR\APP"  -ForegroundColor Green
# Get-ChildItem F:\backup\APP\*.tar.gz
exit
