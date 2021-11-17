## ----------------------------------------- ##
# @Author: WeiyiGeek
# @Description:  Windows Server 安全配置策略基线加固脚本
# @Create Time:  2019年5月6日 11:04:42
# @Last Modified time: 2021-11-15 11:06:31
# @E-mail: master@weiyigeek.top
# @Blog: https://www.weiyigeek.top
# @wechat: WeiyiGeeker
# @Github: https://github.com/WeiyiGeek/SecOpsDev/tree/master/OS-操作系统/Windows/
# @Version: 1.8
# @Runtime: Server 2019 / Windows 10
## ----------------------------------------- ##
# 脚本主要功能说明:
# (1) Windows 系统安全策略相关基础配置
# (2) Windows 默认共享关闭、屏保、超时时间以及WSUS补丁更新。
# (3) Windows 等保主机测评项安全加固配置
## ----------------------------------------- ##

# * 文件输出默认为UTF-8格式
# $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

<#
.SYNOPSIS
Windows Server 安全配置策略基线加固脚本 （脚本将会在Github上持续更新）

.DESCRIPTION
Windows Server 操作系统配置策略 (符合等保3级的关键检查项)
- 系统账号策略 
- 系统事件审核策略
- 系统组策略安全选项策略
- 注册表相关安全策略
- 防火墙服务相关安全策略
- 针对于系统暂无办法通过注册表以及组策略配置的安全加固项

.EXAMPLE
WindowsSecurityReinforce.ps1

.NOTES
注意:不同的版本操作系统以下某些关键项可能会不存在会有一些警告(需要大家提交issue，共同完成)。
#>

# - 系统账号策略 - #
$SysAccountPolicy = @{
  # + 密码最短留存期
  "MinimumPasswordAge" = @{operator="eq";value=1;msg="密码最短留存期"}
  # + 密码最长留存期
  "MaximumPasswordAge" = @{operator="eq";value=90;msg="密码最长留存期"}
  # + 密码长度最小值
  "MinimumPasswordLength" = @{operator="ge";value=14;msg="密码长度最小值"}
  # + 密码必须符合复杂性要求
  "PasswordComplexity" = @{operator="eq";value=1;msg="开启密码符合复杂性要求策略"}
  # + 强制密码历史 N个记住的密码
  "PasswordHistorySize" = @{operator="ge";value=3;msg="强制密码历史N个记住的密码"}
  # + 账户登录失败锁定阈值N次数
  "LockoutBadCount" = @{operator="eq";value=6;msg="账户登录失败锁定阈值次数"}
  # + 账户锁定时间(分钟)
  "ResetLockoutCount" = @{operator="ge";value=15;msg="账户锁定时间(分钟)"}
  # + 复位账户锁定计数器时间(分钟)
  "LockoutDuration" = @{operator="ge";value=15;msg="复位账户锁定计数器时间(分钟)"}
  # + 下次登录必须更改密码
  "RequireLogonToChangePassword" = @{operator="eq";value=0;msg="下次登录必须更改密码"}
  # + 强制过期
  "ForceLogoffWhenHourExpire" = @{operator="eq";value=1;msg="强制过期"}
  # + 当前管理账号登陆名称
  "NewAdministratorName" = @{operator="ne";value='"Admin"';msg="更改当前系统管理账号登陆名称为Admin策略"}
  # + 当前来宾用户登陆名称
  "NewGuestName" = @{operator="ne";value='"Guester"';msg="更改当前系统来宾用户登陆名称为Guester策略"}
  # + 管理员是否被启用
  "EnableAdminAccount" = @{operator="eq";value=1;msg="管理员账户停用与启用策略"}
  # + 来宾用户是否启用
  "EnableGuestAccount" = @{operator="eq";value=0;msg="来宾账户停用与启用策略"}
  # + 指示是否使用可逆加密来存储密码一般禁用(除非应用程序要求超过保护密码信息的需要)
  "ClearTextPassword" = @{operator="eq";value=0;msg="指示是否使用可逆加密来存储密码 (除非应用程序要求超过保护密码信息的需要)"}
  # + 启用时此设置允许匿名用户查询本地LSA策略(0关闭)
  "LSAAnonymousNameLookup" = @{operator="eq";value=0;msg="启用时此设置允许匿名用户查询本地LSA策略 (0关闭)"}
}

# - 系统事件审核策略 - #
$SysEventAuditPolicy  = @{
  # + 审核系统事件(0) [成功(1)、失败(2)] (3)
  AuditSystemEvents = @{operator="eq";value=3;msg="审核系统事件"}
  # + 审核登录事件 成功、失败
  AuditLogonEvents = @{operator="eq";value=3;msg="审核登录事件"}
  # + 审核对象访问 成功、失败
  AuditObjectAccess = @{operator="eq";value=3;msg="审核对象访问"}
  # + 审核特权使用 失败
  AuditPrivilegeUse = @{operator="ge";value=2;msg="审核特权使用"}
  # + 审核策略更改 成功、失败
  AuditPolicyChange = @{operator="eq";value=3;msg="审核策略更改"}
  # + 审核账户管理 成功、失败
  AuditAccountManage = @{operator="eq";value=3;msg="审核账户管理"}
  # + 审核过程追踪 失败
  AuditProcessTracking = @{operator="ge";value=2;msg="审核过程追踪"}
  # + 审核目录服务访问 失败
  AuditDSAccess = @{operator="ge";value=2;msg="审核目录服务访问"}
  # + 审核账户登录事件 成功、失败
  AuditAccountLogon = @{operator="eq";value=3;msg="审核账户登录事件"}
}

# - 系统组策略安全选项策略 - #
$SysSecurityOptionPolicy = @{
  # - 帐户:使用空密码的本地帐户只允许进行控制台登录(启用),注意此设置不影响使用域帐户的登录。(0禁用|1启用)
  LimitBlankPasswordUse = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\LimitBlankPasswordUse=4,1";msg="帐户-使用空密码的本地帐户只允许进行控制台登录(启用)"}
  # - 交互式登录: 不显示上次登录用户名值(启用)
  DontDisplayLastUserName = @{operator="eq";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DontDisplayLastUserName=4,1";msg="交互式登录-不显示上次登录用户名值(启用)"}
  # - 交互式登录: 登录时不显示用户名
  DontDisplayUserName = @{operator="eq";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DontDisplayUserName=4,1";msg="交互式登录: 登录时不显示用户名"}
  # - 交互式登录: 锁定会话时显示用户信息(不显示任何信息)
  DontDisplayLockedUserId = @{operator="eq";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DontDisplayLockedUserId=4,3";msg="交互式登录: 锁定会话时显示用户信息(不显示任何信息)"}
  # - 交互式登录: 无需按 CTRL+ALT+DEL(禁用)
  DisableCAD = @{operator="eq";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DisableCAD=4,0";msg="交互式登录-无需按CTRL+ALT+DEL值(禁用)"}
  # - 交互式登录：计算机不活动限制值为600秒或更少
  InactivityTimeoutSecs = @{operator="eq";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\InactivityTimeoutSecs=4,600";msg="交互式登录-计算机不活动限制值为600秒或更少"}
  # - 交互式登录: 计算机帐户阈值此策略设置确定可导致计算机重启的失败登录尝试次数
  MaxDevicePasswordFailedAttempts = @{operator="le";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\MaxDevicePasswordFailedAttempts=4,10";msg="交互式登录: 此策略设置确定可导致计算机重启的失败登录尝试次数"}
  # - 交互式登录: 试图登录的用户的消息标题
  LegalNoticeCaption = @{operator="eq";value='MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeCaption=1,"安全登陆"';msg="交互式登录: 试图登录的用户的消息标题"}
  # - 交互式登录: 试图登录的用户的消息文本
  LegalNoticeText = @{operator="eq";value='MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeText=7,请谨慎的操作服务器中数据,您所有操作将被记录审计';msg="交互式登录: 试图登录的用户的消息文本"}
  
  # - Microsoft网络客户端: 将未加密的密码发送到第三方 SMB 服务器(禁用)
  EnablePlainTextPassword = @{operator="eq";value="MACHINE\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\EnablePlainTextPassword=4,0";msg="Microsoft网络客户端-将未加密的密码发送到第三方 SMB 服务器(禁用)"}
  # - Microsoft网络服务器：暂停会话前所需的空闲时间数量值为15分钟或更少但不为0
  AutoDisconnect = @{operator="15";value="MACHINE\System\CurrentControlSet\Services\LanManServer\Parameters\AutoDisconnect=4,15";msg="Microsoft网络服务器-暂停会话前所需的空闲时间数量值为15分钟"}
  
  # - 网络安全: 再下一次改变密码时不存储LAN管理器哈希值(启用)
  NoLMHash = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\NoLMHash=4,1";msg="网络安全-在下一次改变密码时不存储LAN管理器哈希值(启用)"}
  
  # - 网络访问: 不允许SAM账户的匿名枚举值为(启用)
  RestrictAnonymousSAM = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymousSAM=4,1";msg="网络访问-不允许SAM账户的匿名枚举值为(启用)"}
  # - 网络访问:不允许SAM账户和共享的匿名枚举值为(启用)
  RestrictAnonymous = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymous=4,1";msg="网络访问-不允许SAM账户和共享的匿名枚举值为(启用)"}
  
  # - 关机:设置确定是否可以在无需登录 Windows 的情况下关闭计算机(禁用)
  ClearPageFileAtShutdown = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management\ClearPageFileAtShutdown=4,0";msg="关机-设置确定是否可以在无需登录 Windows 的情况下关闭计算机(禁用)"}
}

# - 操作系统组策略用户权限管理策略 - #
$SysUserPrivilegePolicy = @{
  # + 操作系统本地关机策略安全
  SeShutdownPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="操作系统本地关机策略"}
  # + 操作系统远程关机策略安全
  SeRemoteShutdownPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="操作系统远程关机策略"}
  # + 取得文件或其他对象的所有权限策略
  SeProfileSingleProcessPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="取得文件或其他对象的所有权限策略"}
  # + 从网络访问此计算机策略
  SeNetworkLogonRight = @{operator="eq";value='*S-1-5-32-544,*S-1-5-32-545,*S-1-5-32-551';msg="从网络访问此计算机策略"}
}

# - 注册表相关安全策略  -
$SysRegistryPolicy = @{
  # + 屏幕自动保护程序
  ScreenSaveActive = @{reg="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaveActive";regtype="String";value=1;operator="eq";msg="开启屏幕自动保护程序策略"}
  # + 屏幕恢复时使用密码保护
  ScreenSaverIsSecure = @{reg="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaverIsSecure";regtype="String";value=1;operator="eq";msg="开启屏幕恢复时使用密码保护策略"}
  # + 屏幕保护程序启动时间
  ScreenSaveTimeOut = @{reg="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaveTimeOut";regtype="String";value=600;operator="le";msg="开启屏幕保护程序启动时间策略"}
  
  # + 禁止全部驱动器自动播放
  DisableAutoplay  = @{reg="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer";name="DisableAutoplay";regtype="DWord";operator="eq";value=1;msg="禁止全部驱动器自动播放"}
  NoDriveTypeAutoRun = @{reg="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer";name="NoDriveTypeAutoRun";regtype="DWord";operator="eq";value=255;msg="禁止全部驱动器自动播放"}
  
  # + 限制IPC共享(禁止SAM帐户和共享的匿名枚举)
  restrictanonymous = @{reg="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa";name="restrictanonymous";regtype="DWord";operator="eq";value=1;msg="不允许SAM账户和共享的匿名枚举值为(启用)"}
  restrictanonymoussam = @{reg="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa";name="restrictanonymoussam";regtype="DWord";operator="eq";value=1;msg="不允许SAM账户的匿名枚举值为(启用)"}

  # + 禁用磁盘共享(SMB)
  AutoShareWks = @{reg="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters";name="AutoShareWks";regtype="DWord";operator="eq";value=0;msg="关闭禁用默认共享策略-Server2012"}
  AutoShareServer = @{reg="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters";name="AutoShareServer";regtype="DWord";operator="eq";value=0;msg="关闭禁用默认共享策略-Server2012"}

  # + 系统、应用、安全、PS日志查看器大小(单位字节)设置(此处设置默认的两倍配置-建议一定通过日志采集平台采集系统日志比如ELK)
  EventlogSystemMaxSize = @{reg="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\System";name="MaxSize";regtype="DWord";operator="ge";value=41943040;msg="系统基日志配核查-系统日志查看器大小设置策略"}
  EventlogApplicationMaxSize = @{reg="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Application";name="MaxSize";regtype="DWord";operator="ge";value=41943040;msg="系统日志基配核查-应用日志查看器大小设置策略"}
  EventlogSecurityMaxSize = @{reg="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Security";name="MaxSize";regtype="DWord";operator="ge";value=41943040;msg="系统日志基配核查-安全日志查看器大小设置策略"}
  EventlogPSMaxSize = @{reg="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Windows PowerShell";name="MaxSize";regtype="DWord";operator="ge";value=31457280;msg="系统日志基配核查-PS日志查看器大小设置策略"}

  # + 远程桌面开启与关闭
  fDenyTSConnections = @{reg='HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server';name='fDenyTSConnections';regtype="DWord";operator="eq";value=0;msg="是否禁用远程桌面服务-1则为禁用"}
  UserAuthentication = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp';name='UserAuthentication ';regtype="DWord";operator="eq";value=1;msg="只允许运行带网络级身份验证的远程桌面的计算机连接"}
  RDPTcpPortNumber = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp';name='PortNumber';regtype="DWord";operator="eq";value=39393;msg="远程桌面服务端口RDP-Tcp非3389"}
  TDSTcpPortNumber = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp';name='PortNumber';regtype="DWord";operator="eq";value=39393;msg="远程桌面服务端口TDS-Tcp非3389"}

  # + 防火墙相关操作设置（开启、协议、服务）
  DomainEnableFirewall  = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile';name='EnableFirewall';regtype="DWord";operator="eq";value=1;msg="开启域网络防火墙"}
  StandardEnableFirewall = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\StandardProfile';name='EnableFirewall';regtype="DWord";operator="eq";value=1;msg="开启专用网络防火墙"}
  PPEnableFirewall = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\PublicProfile';name='EnableFirewall';regtype="DWord";operator="eq";value=1;msg="开启公用网络防火墙"}

  # + 源路由欺骗保护
  DisableIPSourceRouting = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters';name='DisableIPSourceRouting';regtype="DWord";operator="eq";value=2;msg="源路由欺骗保护"}

  # + 碎片攻击保护
  EnablePMTUDiscovery = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters';name='EnablePMTUDiscovery';regtype="DWord";operator="eq";value=1;msg="碎片攻击保护"}

  # 【TCP/IP 协议栈的调整可能会引起某些功能的受限，管理员应该在进行充分了解和测试的前提下进行此项工作】
  # + 防SYN洪水攻击: 
  # SynAttackProtect = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters';name='EnablePMTUDiscovery';regtype="DWord";operator="eq";value=1;msg="设置防syn洪水攻击"}
  # TcpMaxHalfOpen = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters';name='TcpMaxHalfOpen';regtype="DWord";operator="eq";value=500;msg="允许的最大半开连接数"}
  # TcpMaxHalfOpenRetried = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters';name='TcpMaxHalfOpenRetried';regtype="DWord";operator="eq";value=400;msg="处于至少已发送一次重传的 SYN_RCVD 状态中的TCP连接数"}
  # + 防止DDOS攻击保护 
  # EnableICMPRedirect = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters';name='EnableICMPRedirect';regtype="DWord";operator="eq";value=0;msg="防止DDOS攻击保护,不启用 ICMP 重定向"}

  # + 启用并正确配置WSUS（自定义WSUS地址）启用 (一般中大企业都会有自己的WSUS补丁服务器)，你需要将下述http://wsus.weiyigeek.top改为企业中自建的地址
  # 启用策略组“配置自动更新”
  AUOptions = @{reg="HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU";name="AUOptions";regtype="DWord";operator="eq";value=3;msg="自动下载并计划安装(4)-建议设置3自动下载并通知安装"}
  AutomaticMaintenanceEnabled = @{reg="HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU";name="AutomaticMaintenanceEnabled";regtype="DWord";operator="eq";value=1;msg="启用自动维护"}
  NoAutoUpdate = @{reg="HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU";name="NoAutoUpdate";regtype="DWord";operator="eq";value=0;msg="关闭无自动更新设置"}
  ScheduledInstallDay = @{reg="HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU";name="ScheduledInstallDay";regtype="DWord";operator="eq";value=7;msg="计划安装日期为每周六"}
  ScheduledInstallTime = @{reg="HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU";name="ScheduledInstallTime";regtype="DWord";operator="eq";value=1;msg="计划安装时间为凌晨1点"}
  # 启用策略组（指定Intranet Microsoft更新服务位置）
  UseWUServer = @{reg="HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU";name="UseWUServer";regtype="DWord";operator="eq";value=1;msg="指定Intranet Microsoft更新服务补丁服务器"}
  WUServer = @{reg="HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate";name="WUServer";regtype="String";value="http://wsus.weiyigeek.top";operator="eq";msg="设置检测更新的intranet更新服务"}
  WUStatusServer = @{reg="HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate";name="WUStatusServer";regtype="String";value="http://wsus.weiyigeek.top";operator="eq";msg="设置Intranet统计服务器"}
  UpdateServiceUrlAlternate = @{reg="HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate";name="UpdateServiceUrlAlternate";regtype="String";value="http://wsus.weiyigeek.top";operator="eq";msg="设置备用下载服务器"}
}



################################################################################################################################
# **********************#
# * 全局公用工具依赖函数  *  
# **********************#
function F_Logging {
<#
.SYNOPSIS
F_Logging 函数全局工具
.DESCRIPTION
用于输出脚本执行结果并按照不同的日志等级输出显示到客户终端上。
.EXAMPLE
F_Logging -Level [Info|Warning|Error] -Msg "测试输出字符串"
#>
  param (
    [Parameter(Mandatory=$true)]$Msg,
    [ValidateSet("Info","Warning","Error")]$Level
  )

  switch ($Level) {
    Info { 
      Write-Host "[INFO] ${Msg}" -ForegroundColor Green;
    }
    Warning {
      Write-Host "[WARN] ${Msg}" -ForegroundColor Yellow;
    }
    Error { 
      Write-Host "[ERROR] ${Msg}" -ForegroundColor Red;
    }
    Default {
      Write-Host "[*] F_Logging 日志 Level 等级错误`n Useage： F_Logging -Level [Info|Warning|Error] -Msg '测试输出字符串'" -ForegroundColor Red;
    }
  }
}


Function F_IsCurrentUserAdmin
{ 
<#
.SYNOPSIS
F_IsCurrentUserAdmin 函数：全局公用工具依赖。
.DESCRIPTION
判断当前运行的powershell终端是否管理员执行,返回值 true 或者 false
.EXAMPLE
F_IsCurrentUserAdmin
#>
  $user = [Security.Principal.WindowsIdentity]::GetCurrent(); 
  (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) 
} 


function F_Detection {
<#
.SYNOPSIS
F_Detection 函数: 全局公用工具依赖。
.DESCRIPTION
函数用于检测 config.cfg 关键项是否匹配并返回相应的结果，返回值 1 或者 0。
.EXAMPLE
F_Detection -Value $Value -Operator $Operator -DefaultValue $DefaultValue
#>
  param (
    [Parameter(Mandatory=$true)]$Value,
    [Parameter(Mandatory=$true)]$Operator,
    [Parameter(Mandatory=$true)]$DefaultValue  
  )
  if ( $Operator -eq "eq" ) {
    if ( $Value -eq "$DefaultValue" ) {return 1;} else { return 0;}
  } elseif ($Operator -eq  "ne" ) {
    if ( $Value -ne $DefaultValue ) {return 1;} else { return 0;}
  } elseif ($Operator -eq  "le") {
    if ( $Value -le $DefaultValue ) {return 1;} else { return 0;}
  } elseif ($Operator -eq "ge") {
    if ( $Value -ge $DefaultValue ) {return 1;} else { return 0;}
  }
}


function F_GetRegPropertyValue {
<#
.SYNOPSIS
F_GetRegPropertyValue 函数: 全局公用工具依赖函数。
.DESCRIPTION
函数用于获取指定键与值并与预定义的进行对比，正常返回结果为1或者0，如果键不存在则返回NotExist。
.EXAMPLE
An example
#>
  param (
    [Parameter(Mandatory=$true)][String]$Key,
    [Parameter(Mandatory=$true)][String]$Name,
    [Parameter(Mandatory=$true)][String]$Operator,
    [Parameter(Mandatory=$true)]$DefaultValue
  )

  try {
    $Value = Get-ItemPropertyValue -Path "Registry::$Key" -Name $Name -ErrorAction Ignore -WarningAction Ignore 
    $Result = F_Detection -Value $Value -Operator $Operator -DefaultValue $DefaultValue
    return $Result
  } catch {
    F_Logging -Level Warning -Msg "[*] $Key - $Name - NotExist"
    return 'NotExist'
  }
}



function F_SeceditReinforce() {
<#
.SYNOPSIS
F_SeceditReinforce 函数：实现系统策略组配置项对比和修改。
.DESCRIPTION
针对 config.cfg 安全配置项进行检测并修改，主要涉及系统账号策略设置、系统事件审核策略设置、系统组策略安全选项配置、操作系统组用户权限管理策略配置
.EXAMPLE
F_SeceditReinforce
#>
  # - 系统账号策略设置
  $Hash = $SysAccountPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String -AllMatches -Pattern "^$($Name.toString())"
    if ($Flag) {
      F_Logging -Level Info -Msg "[*] Update - $Name"
      $Line = $Flag -split " = "
      $Result = F_Detection -Value $Line[1] -Operator $SysAccountPolicy["$($Line[0])"].operator -DefaultValue $SysAccountPolicy["$($Line[0])"].value
      $NewLine = $Line[0] + " = " + $SysAccountPolicy["$($Line[0])"].value
      # - 在不匹配时进行关键项替换配置
      if ( -not($Result) -or $Line[0] -eq "NewGuestName" -or $Line[0] -eq "NewAdministratorName" ) {
	      write-host "    $Flag -->> $NewLine"
        # 此处采用正则进行匹配系统账号策略相关项,防止后续
        $SecConfig = $SecConfig -replace "$Flag", "$NewLine" 
      }
    } else {
      F_Logging -Level Info -Msg "[+] Insert - $Name"
      $NewLine = $Name + " = " + $SysAccountPolicy["$Name"].value
      Write-Host "    $NewLine "
      # - 在不存在该配置项时进行插入
      $SecConfig = $SecConfig -replace "\[System Access\]", "[System Access]`n$NewLine"
    }
  }

  # - 系统事件审核策略设置
  $Hash = $SysEventAuditPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      F_Logging -Level Info -Msg "[*] Update - $Name"
      $Line = $Flag -split " = "
      $Result = F_Detection -Value $Line[1] -Operator $SysEventAuditPolicy["$($Line[0])"].operator -DefaultValue $SysEventAuditPolicy["$($Line[0])"].value
      $NewLine = $Line[0] + " = " + $SysEventAuditPolicy["$($Line[0])"].value
      # - 在不匹配时进行关键项替换配置
      if (-not($Result)) {
        $SecConfig = $SecConfig -replace "$Flag", "$NewLine" 
      }
    } else {
      F_Logging -Level Info -Msg "[+] Insert - $Name"
      $NewLine = $Name + " = " + $SysEventAuditPolicy["$Name"].value
      Write-Host "  $NewLine"
      # - 在不存在该配置项时进行插入
      $SecConfig = $SecConfig -replace "\[Event Audit\]", "[Event Audit] `n$NewLine"
    }
  }

  # - 系统组策略安全选项配置 - #
  $Hash = $SysSecurityOptionPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      F_Logging -Level Info -Msg "[*] Update - $Name"
      # 源字符串
      $Line = $Flag -split "="
      # 目标字符串
      $Value = $SysSecurityOptionPolicy["$($Name)"].value -split "="
      $Result = F_Detection -Value $Line[1] -Operator $SysSecurityOptionPolicy["$($Name)"].operator -DefaultValue $Value[1] 
      $NewLine = $Line[0] + "=" + $Value[1]
      if (-not($Result)) {
        $SecConfig = $SecConfig -Replace ([Regex]::Escape("$Flag")),"$NewLine" 
      }
    } else {
      F_Logging -Level Info -Msg "[+] Insert - $Name"
      $NewLine = $SysSecurityOptionPolicy["$Name"].value
      Write-Host "   $NewLine"
      # 不采用正则匹配原字符串(值得学习)
      $SecConfig = $SecConfig -Replace ([Regex]::Escape("[Registry Values]")),"[Registry Values]`n$NewLine"
    }
  }

  # - 操作系统组用户权限管理策略配置
  $Hash = $SysUserPrivilegePolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      F_Logging -Level Info -Msg "[*] Update - $Name"
      $Line = $Flag -split " = "
      $Result = F_Detection -Value $Line[1] -Operator $SysUserPrivilegePolicy["$($Line[0])"].operator -DefaultValue $SysUserPrivilegePolicy["$($Line[0])"].value
      $NewLine = $Line[0] + " = " + $SysUserPrivilegePolicy["$($Line[0])"].value
      if (-not($Result)) {
        $SecConfig = $SecConfig -Replace ([Regex]::Escape("$Flag")), "$NewLine" 
      }
    } else {
      F_Logging -Level Info -Msg "[+] Insert - $Name"
      $NewLine = $Name + " = " + $SysUserPrivilegePolicy["$Name"].value
      Write-Host "    $NewLine"
      $SecConfig = $SecConfig -Replace ([Regex]::Escape("[Privilege Rights]")),"[Privilege Rights]`n$NewLine"
    }
  }
   # 将生成的本地安全组策略配置输到`secconfig.cfg`,【坑】非常注意文件编码格式为UTF16-LE,此时需要添加-Encoding参数并指定为string
   $SecConfig | Out-File secconfig.cfg -Encoding string
}


function F_SysRegistryReinforce()  {
<#
.SYNOPSIS
F_SysRegistryReinforce 函数针对于注册表中系统相关配置。
.DESCRIPTION
针对操作系统注册表安全配置项与SysRegistryPolicy哈希表的键值进行检测与设置。
.EXAMPLE
F_SysRegistryReinforce 
#>
  # - 满足等级保护相关基础配置
  $Hash = $SysRegistryPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Result = F_GetRegPropertyValue -Key $SysRegistryPolicy.$Name.reg -Name $SysRegistryPolicy.$Name.name -Operator $SysRegistryPolicy.$Name.operator -DefaultValue $SysRegistryPolicy.$Name.value
    F_Logging -Level Info -Msg "Get-ItemProperty -Path Registry::$($SysRegistryPolicy.$Name.reg)"
    if ( $Result -eq 'NotExist' ){
      # - 判断注册表项是否存在不存在则创建
      if (-not(Test-Path -Path "Registry::$($SysRegistryPolicy.$Name.reg)")){
        F_Logging -Level Info -Msg "正在创建 $($SysRegistryPolicy.$Name.reg) 注册表项......"
        New-Item -Path "registry::$($SysRegistryPolicy.$Name.reg)" -Force
      }
      # - 可能的枚举值包括"String、ExpandString、Binary、DWord、MultiString、QWord、Unknown"
      New-ItemProperty -Path "Registry::$($SysRegistryPolicy.$Name.reg)" -Name $SysRegistryPolicy.$Name.name -PropertyType $SysRegistryPolicy.$Name.regtype -Value $SysRegistryPolicy.$Name.value
    } elseif ( $Result -eq 0 ) {
      Set-ItemProperty -Path "Registry::$($SysRegistryPolicy.$Name.reg)" -Name $SysRegistryPolicy.$Name.name -Value $SysRegistryPolicy.$Name.value
    }
  }
}


function F_ServiceManager() {
<#
.SYNOPSIS
F_ServiceManager 函数：针对于系统中相关服务管理操作
.DESCRIPTION
主要对系统中某些服务进行停止禁用
.EXAMPLE
F_ServiceManager -Name server -Operator restart -StartType Automatic
#>
  param (
    [Parameter(Mandatory=$true)]$Name,
    [ValidateSet("Start","Stop","Restart")]$Operator,
    [ValidateSet("Automatic","Manual","Disabled","Boot","System")]$StartType
  )
  # - 验证服务是否存在
  F_Logging -Level Info -Msg "正在对 $Name 服务进行操作管理......."
  $ServiceStatus = (Get-Service $Name -ErrorAction SilentlyContinue).Status
  if( -not($ServiceStatus.Length) ) {
    F_Logging -Level Error -Msg "$Name Service is not exsit with current system!!!!!!"
    return
  }

  # - 根据$Operator操作服务启动、停止、重启
  switch ($Operator) {
    Start { 
      if ( "$ServiceStatus" -ne "Running" ) {
        F_Logging -Level Info -Msg "正在启动 $Name 服务";Start-Service -Name $Name -Force
      }
    }
    Stop { 
      if ( "$ServiceStatus" -ne "Stopped" ) {
        F_Logging -Level Warning -Msg "正在停止 $Name 服务";Stop-Service -Name $Name -Force
      }
    }
    Restart {
      F_Logging -Level Warning -Msg "正在重启 $Name 服务";Restart-Service -Name $Name -Force
    }
    Default { F_Logging -Level Info -Msg "未对 $Name 服务做任何操作!" }
  }
  

  # - 根据$StartType设置服务启动类型
  switch ($StartType) {
    Automatic { Set-Service -Name $Name -StartupType Automatic}
    Manual { Set-Service -Name $Name -StartupType Manual }
    Disabled { Set-Service -Name $Name -StartupType Disabled}
    Boot { Set-Service -Name $Name -StartupType Boot}
    System {Set-Service -Name $Name -StartupType System }
    Default {F_Logging -Level Info -Msg "未对 $Name 服务做任何自启配置操作!"}
  }
}



Function F_ExtentionReinforce() {
<#
.SYNOPSIS
F_ExtentionReinforce 函数：针对于系统暂无办法通过注册表以及组策略配置的将在此处执行。
.DESCRIPTION
执行系统加固的相关命令，其中保护PowerShell或者cmd相关命令
.EXAMPLE
F_ExtentionReinforce 
#>
  # [+] 禁用共享服务以及删除当前主机中所有共享

  F_ServiceManager -Name lanmanserver -Operator Stop -StartType Manual
  (gwmi -class win32_share).delete()
  # 方式2.(Get-WmiObject -class win32_share).delete()

  # [+] 启用windows防火墙以及防火墙相关
  netsh advfirewall set allprofiles state on
  # 启用、或者禁用文件和打印机共享(回显请求 - ICMPv4-In) 根据需求而定
  # Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In
  Disable-NetFirewallRule  -Name FPS-ICMP4-ERQ-In
  Get-NetFirewallRule -Name "CustomSecurity-Remote-Desktop-Port" -ErrorAction SilentlyContinue
  if ($?) {
    # 允许其它主机访问 Remote-Desktop-Port 的39393端口。
    New-NetFirewallRule -Name "CustomSecurity-Remote-Desktop-Port" -DisplayName "CustomSecurity-Remote-Desktop-Port" -Description "CustomSecurity-Remote-Desktop-Port" -Direction Inbound -LocalPort 39393 -Protocol TCP -Action Allow -Enabled True
  }
}

# Function F_SensitiveFile() {
# <#
# .SYNOPSIS
# F_SensitiveFile 函数：针对于系统中相关服务的敏感文件检测。（后续扩充）
# .DESCRIPTION
# 针对 config.cfg 安全配置项进行检测并修改
# .EXAMPLE
# F_SensitiveFile 
# #>
#   $SensitiveFile = @("%systemroot%\system32\inetsrv\iisadmpwd")
#   if (Test-Path -Path $SensitiveFile[$i]) {
#     # 1.删除具有任何文件扩展名的文件
#     Remove-Item C:\Test\*.* # == Del C:\Test\*.*
#     Remove-Item -Path C:\Test\file.txt -Force 

#     # 2.删除特殊条件的文件或者目录
#     Remove-Item -Path C:\temp\DeleteMe -Recurse # 递归删除子文件夹中的文件
#     }
# }

function Main {
<#
.SYNOPSIS
main 函数程序执行入口
.DESCRIPTION
调用上述编写的相关检测加固函数
.EXAMPLE
main
#>
F_Logging -Level Info -Msg "#################################################################################"
F_Logging -Level Info -Msg "- @Desc: Windows Server 安全配置策略基线加固脚本 [将会在Github上持续更新-star]"
F_Logging -Level Info -Msg "- @Author: WeiyiGeek"
F_Logging -Level Info -Msg "- @Blog: https://www.weiyigeek.top"
F_Logging -Level Info -Msg "- @Github: https://github.com/WeiyiGeek/SecOpsDev/tree/master/OS-操作系统/Windows"
$StartTime = Get-date -Format 'yyyy-M-d H:m:s'
F_Logging -Level Info -Msg "#################################################################################`n"

# 1.当前系统策略配置文件导出 (注意必须系统管理员权限运行) 
F_Logging -Level Info -Msg "- 正在检测当前运行的PowerShell终端是否管理员权限...`n"
$flag = F_IsCurrentUserAdmin
if (!($flag)) {
  F_Logging -Level Error -Msg "- 脚本执行发生错误,请使用管理员权限运行该脚本..例如: Start-Process powershell -Verb runAs....`n"
  F_Logging -Level Warning -Msg "- 正在退出执行该脚本......`n"
  return
}

# 2.导出当前系统策略配置文件后验证文件是否存在以及原始配置文件备份。
secedit /export /cfg config.cfg /quiet
start-sleep 3
if ( -not(Test-Path -Path config.cfg) ) {
  F_Logging -Level Error -Msg "- 当前系统策略配置文件 config.cfg 不存在,请检查......"
  F_Logging -Level Warning -Msg "- 正在退出执行该脚本......"
  return
} else { 
  Copy-Item -Path config.cfg -Destination config.cfg.bak -Force
}
$Config = Get-Content -path config.cfg
$SecConfig = $Config.Clone()

# 3.进行系统策略配置安全加固
F_SeceditReinforce

# 4.当系统策略配置安全加固完成后将生成的secconfig.cfg导入进系统策略中。
secedit /configure /db secconfig.sdb /cfg secconfig.cfg

# 5.进行系统注册表相关配置安全加固
F_SysRegistryReinforce

# 6.系统扩展相关配置安全加固
F_ExtentionReinforce

# 7.程序执行完毕
$EndTime = Get-date -Format 'yyyy-M-d H:m:s'
F_Logging -Level Info -Msg "- 该操作系统安全加固已完毕......`n开始时间：${StartTime}`n完成时间: ${EndTime}"
}

Main