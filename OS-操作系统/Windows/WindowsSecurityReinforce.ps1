## ----------------------------------------- ##
# @Author: WeiyiGeek
# @Description:  WindowsServer Security Initiate
# @Create Time:  2019年5月6日 11:04:42
# @Last Modified time: 2021-11-15 11:06:31
# @E-mail: master@weiyigeek.top
# @Blog: https://www.weiyigeek.top
# @wechat: WeiyiGeeker
# @Github: https://github.com/WeiyiGeek/SecOpsDev/tree/master/OS-操作系统/Windows/
# @Version: 3.2
# @Runtime: Server 2019 / Windows 10
## ----------------------------------------- ##
# 脚本主要功能说明:
# (1) CentOS7系统初始化操作包括IP地址设置、基础软件包更新以及安装加固。
# (2) CentOS7系统容器以及JDK相关环境安装。
# (3) CentOS7系统中异常错误日志解决。
# (4) CentOS7系统中常规服务安装配置，加入数据备份目录。
## ----------------------------------------- ##


# 系统策略配置文件拉取(注意必须系统管理员权限运行) *
secedit /export /cfg config.cfg /quiet
if ( -not(Test-Path -Path config.cfg)) { Write-Host "[-] 请使用管理员权限运行该脚本！" -ForegroundColor Red; exit; } else { Copy-Item -Path config.cfg -Destination config.cfg.bak -Force }
$Config = Get-Content -path config.cfg
$SecConfig = $Config.Clone()
$StartTime = Get-date -Format 'yyyy-M-d H:m:s'

<#
.SYNOPSIS
F_Detection 函数: 全局公用工具依赖。
.DESCRIPTION
函数用于检测 config.cfg 关键项是否匹配并返回相应的结果。
.EXAMPLE
An example
#>
function F_Detection {
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


<#
.SYNOPSIS
F_GetRegPropertyValue 函数: 全局公用工具依赖函数。
.DESCRIPTION
函数用于获取指定键与值并进行对比并且如果键不存在则返回NotExist
.EXAMPLE
An example
#>

function F_GetRegPropertyValue {
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
    Write-Host "[-] $Key - $Name - NotExist" -ForegroundColor Red
    return 'NotExist'
  }
}



<#
.SYNOPSIS
F_SeceditReinforce 函数针对于策略组进行修改

.DESCRIPTION
针对 config.cfg 安全配置项进行检测并修改

.EXAMPLE
An example
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
  "NewAdministratorName" = @{operator="ne";value='"cqzk_Admin"';msg="当前系统管理账号登陆名称策略"}
  # + 当前来宾用户登陆名称
  "NewGuestName" = @{operator="ne";value='"cqzk_Guest"';msg="当前系统来宾用户登陆名称策略"}
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
  LegalNoticeText = @{operator="eq";value='MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeText=7,请谨慎的操作数据,所有操作将被审计';msg="交互式登录: 试图登录的用户的消息文本"}
  
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
function F_SeceditReinforce() {
  # - 系统账号策略设置
  $Hash = $SysAccountPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      Write-Host "[-] Update - $Name"
      $Line = $Flag -split " = "
      $Result = F_Detection -Value $Line[1] -Operator $SysAccountPolicy["$($Line[0])"].operator -DefaultValue $SysAccountPolicy["$($Line[0])"].value
      $NewLine = $Line[0] + " = " + $SysAccountPolicy["$($Line[0])"].value
      # - 在不匹配时进行关键项替换配置
      if ( -not($Result) -or $Line[0] -eq "NewGuestName" -or $Line[0] -eq "NewAdministratorName" ) {
	    write-host "### $Flag - $NewLine##"
        $SecConfig = $SecConfig -replace "$Flag", "$NewLine" 
      }
    } else {
      Write-Host "[+] Insert - $Name"
      $NewLine = $Name + " = " + $SysAccountPolicy["$Name"].value
      Write-Host $NewLine 
      # - 在不存在该配置项时进行插入
      $SecConfig = $SecConfig -replace "\[System Access\]", "[System Access]`n$NewLine"
    }
  }

  # - 系统事件审核策略设置
  $Hash = $SysEventAuditPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      Write-Host "[-] Update - $Name"
      $Line = $Flag -split " = "
      $Result = F_Detection -Value $Line[1] -Operator $SysEventAuditPolicy["$($Line[0])"].operator -DefaultValue $SysEventAuditPolicy["$($Line[0])"].value
      $NewLine = $Line[0] + " = " + $SysEventAuditPolicy["$($Line[0])"].value
      # - 在不匹配时进行关键项替换配置
      if (-not($Result)) {
        $SecConfig = $SecConfig -replace "$Flag", "$NewLine" 
      }
    } else {
      Write-Host "[+] Insert - $Name"
      $NewLine = $Name + " = " + $SysEventAuditPolicy["$Name"].value
      Write-Host $NewLine 
      # - 在不存在该配置项时进行插入
      $SecConfig = $SecConfig -replace "\[Event Audit\]", "[Event Audit] `n$NewLine"
    }
  }

  # - 系统组策略安全选项配置 - #
  $Hash = $SysSecurityOptionPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      Write-Host "[-] Update - $Name"
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
      Write-Host "[+] Insert - $Name"
      $NewLine = $SysSecurityOptionPolicy["$Name"].value
      Write-Host $NewLine
      # 不采用正则匹配原字符串(值得学习)
      $SecConfig = $SecConfig -Replace ([Regex]::Escape("[Registry Values]")),"[Registry Values]`n$NewLine"
    }
  }

  # - 操作系统组用户权限管理策略配置
  $Hash = $SysUserPrivilegePolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Flag = $Config | Select-String $Name.toString()
    if ($Flag) {
      Write-Host "[-] Update - $Name"
      $Line = $Flag -split " = "
      $Result = F_Detection -Value $Line[1] -Operator $SysUserPrivilegePolicy["$($Line[0])"].operator -DefaultValue $SysUserPrivilegePolicy["$($Line[0])"].value
      $NewLine = $Line[0] + " = " + $SysUserPrivilegePolicy["$($Line[0])"].value
      if (-not($Result)) {
        $SecConfig = $SecConfig -Replace ([Regex]::Escape("$Flag")), "$NewLine" 
      }
    } else {
      Write-Host "[+] Insert - $Name"
      $NewLine = $Name + " = " + $SysUserPrivilegePolicy["$Name"].value
      Write-Host $NewLine 
      $SecConfig = $SecConfig -Replace ([Regex]::Escape("[Privilege Rights]")),"[Privilege Rights]`n$NewLine"
    }
  }
  # 将组策略本地安全配置输出secconfig.cfg注意不能添加编码格式否则导入时会报格式错误。
  $SecConfig | Out-File secconfig.cfg
}

<#
.SYNOPSIS
F_SysRegistryReinforce 函数针对于注册表中系统相关配置。

.DESCRIPTION
针对 config.cfg 安全配置项进行检测并修改

.EXAMPLE
An example
#>

# - 注册表相关安全策略  -
$SysRegistryPolicy = @{
  # + 屏幕自动保护程序
  ScreenSaveActive = @{reg="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaveActive";regtype="String";value=1;operator="eq";msg="开启屏幕自动保护程序策略"}
  # + 屏幕恢复时使用密码保护
  ScreenSaverIsSecure = @{reg="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaverIsSecure";regtype="String";value=1;operator="eq";msg="开启屏幕恢复时使用密码保护策略"}
  # + 屏幕保护程序启动时间
  ScreenSaveTimeOut = @{reg="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaveTimeOut";regtype="String";value=600;operator="le";msg="开启屏幕保护程序启动时间策略"}
  
  # + 禁止全部驱动器自动播放
  NoDriveTypeAutoRun = @{reg="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer";name="NoDriveTypeAutoRun";regtype="String";operator="eq";value=233;msg="禁止全部驱动器自动播放"}
  
  # + 检查关闭默认共享盘
  restrictanonymous = @{reg="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa";name="restrictanonymous";regtype="String";operator="eq";value=1;msg="关闭默认共享盘策略"}

  # + 远程桌面开启与关闭
  fDenyTSConnections = @{reg='HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server';Name='fDenyTSConnections';regtype="DWord";operator="eq";value=0;msg="是否禁用远程桌面服务"}
  RDPTcpPortNumber = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\';Name='PortNumber';regtype="DWord";operator="eq";value=39393;msg="远程桌面服务端口RDP-Tcp非3389"}
  TDSTcpPortNumber = @{reg='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp\';Name='PortNumber';regtype="DWord";operator="eq";value=39393;msg="远程桌面服务端口TDS-Tcp非3389"}


  #tes = @{reg='';Name='';regtype="";operator="eq";value=39393;msg="远程桌面服务端口非3389"}
}

function F_SysRegistryReinforce()  {
  # - 满足等级保护相关基础配置
  $Hash = $SysRegistryPolicy.Clone()
  foreach ( $Name in $Hash.keys ) {
    $Result = F_GetRegPropertyValue -Key $SysRegistryPolicy.$Name.reg -Name $SysRegistryPolicy.$Name.name -Operator $SysRegistryPolicy.$Name.operator -DefaultValue $SysRegistryPolicy.$Name.value
    if ( $Result -eq 'NotExist' ){
    
      # 判断注册表项是否存在不存在则创建
      if (-not(Test-Path -Path "Registry::$($SysRegistryPolicy.$Name.reg)")){
         New-Item -Path "registry::$($SysRegistryPolicy.$Name.reg)" -Force
      }
      # 可能的枚举值包括"String、ExpandString、Binary、DWord、MultiString、QWord、Unknown"
      New-ItemProperty -Path "Registry::$($SysRegistryPolicy.$Name.reg)" -Name $SysRegistryPolicy.$Name.name -PropertyType $SysRegistryPolicy.$Name.regtype -Value $SysRegistryPolicy.$Name.value
    } elseif ( $Result -eq 0 ) {
      Set-ItemProperty -Path "Registry::$($SysRegistryPolicy.$Name.reg)" -Name $SysRegistryPolicy.$Name.name -Value $SysRegistryPolicy.$Name.value
    }
  }
}

$SensitiveFile = @("%systemroot%\system32\inetsrv\iisadmpwd")

Function F_SensitiveFile() {
  if (Test-Path -Path $SensitiveFile[$i]) {
    # 1.删除具有任何文件扩展名的文件
    Remove-Item C:\Test\*.* # == Del C:\Test\*.*
    Remove-Item -Path C:\Test\file.txt -Force 

    # 2.删除特殊条件的文件或者目录
    Remove-Item -Path C:\temp\DeleteMe -Recurse # 递归删除子文件夹中的文件
    }
}



Write-Host "[-] 安全加固已启动......" -ForegroundColor Green
F_SeceditReinforce
secedit /configure /db secconfig.sdb /cfg secconfig.cfg
F_SysRegistryReinforce
Write-Host "[-] 安全加固已完毕......" -ForegroundColor Green