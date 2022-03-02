#######################################################
# @Author: WeiyiGeek
# @Description:  Windows Server 安全配置策略基线检测脚本
# @Create Time:  2019年5月6日 11:04:42
# @Last Modified time: 2021-11-15 11:06:31
# @E-mail: master@weiyigeek.top
# @Blog: https://www.weiyigeek.top
# @wechat: WeiyiGeeker
# @Github: https://github.com/WeiyiGeek/SecOpsDev/tree/master/OS-操作系统/Windows/
# @Version: 1.8
# @Runtime: Server 2019 / Windows 10
#######################################################

<#
.SYNOPSIS
Windows Server 安全配置策略基线检测脚本 （脚本将会在Github上持续更新）

.DESCRIPTION
Windows Server 操作系统配置策略核查 (符合等保3级的关键检查项)

.EXAMPLE
WindowsSecurityBaseLine.ps1 -Executor WeiyiGeek -MsrcUpdate False
- Executor : 脚本执行者
- MsrcUpdate : 是否在线拉取微软安全中心的服务器安全补丁列表信息(建议一台主机拉取好之后将WSUSList.json和WSUSListId.json拷贝到当前脚本同级目录下)

.NOTES
注意:不同的版本操作系统以下某些关键项可能会不存在会有一些警告(需要大家提交issue，共同完成)。
#>
[Cmdletbinding()]
param(
  [Parameter(Mandatory=$true)][String]$Executor,
  [Boolean]$MsrcUpdate
)

# * 文件输出默认为UTF-8格式
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'


################################################################################################################################
# **********************#
# * 全局公用工具依赖函数  *  
# **********************#
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

function F_Logging {
<#
.SYNOPSIS
F_Logging 日志输出函数
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

function F_Tools {
<#
.SYNOPSIS
F_Tools 检测对比函数
.DESCRIPTION
验证判断传入的字段是否与安全加固字段一致
.EXAMPLE
F_Tools -Key "ItemDemo" -Value "2" -Operator "eq" -DefaultValue "1"  -Msg "对比ItemDemo字段值与预设值"
#>
  param (
    [Parameter(Mandatory=$true)][String]$Key,
    [Parameter(Mandatory=$true)]$Value,
    [Parameter(Mandatory=$true)]$DefaultValue,
    [String]$Msg,
    [String]$Operator
  )
  
  if ( $Operator -eq  "eq" ) {
    if ( $Value -eq $DefaultValue ) {
      $Result = @{"$($Key)"="[合格项]|$($Value)|$($DefaultValue)|$($Msg)-【符合】等级保护标准."}
      Write-Host "$($Key)"=" [合格项]|$($Value)|$($DefaultValue)|$($Msg)-【符合】等级保护标准." -ForegroundColor White
      return $Result
    } else {
      $Result = @{"$($Key)"="[异常项]|$($Value)|$($DefaultValue)|$($Msg)-【不符合】等级保护标准."}
      Write-Host "$($Key)"=" [异常项]|$($Value)|$($DefaultValue)|$($Msg)-【不符合】等级保护标准." -ForegroundColor red
      return $Result
    }

  } elseif ($Operator -eq  "ne" ) {

    if ( $Value -ne $DefaultValue ) {
      $Result = @{"$($Key)"="[合格项]|$($Value)|$($DefaultValue)|$($Msg)-【符合】等级保护标准."}
      Write-Host "$($Key)"=" [合格项]|$($Value)|$($DefaultValue)|$($Msg)-【符合】等级保护标准." -ForegroundColor White
      return $Result
    } else {
      $Result = @{"$($Key)"="[异常项]|$($Value)|$($DefaultValue)|$($Msg)-【不符合】等级保护标准."}
      Write-Host "$($Key)"=" [异常项]|$($Value)|$($DefaultValue)|$($Msg)-【不符合】等级保护标准." -ForegroundColor red
      return $Result
    }

  } elseif ($Operator -eq  "le") {

    if ( $Value -le $DefaultValue ) {
      $Result = @{"$($Key)"="[合格项]|$($Value)|$($DefaultValue)|$($Msg)-【符合】等级保护标准."}
      Write-Host "$($Key)"=" [合格项]|$($Value)|$($DefaultValue)|$($Msg)-【符合】等级保护标准." -ForegroundColor White
      return $Result
    } else {
      $Result = @{"$($Key)"="[异常项]|$($Value)|$($DefaultValue)|$($Msg)-【不符合】等级保护标准."}
      Write-Host "$($Key)"=" [异常项]|$($Value)|$($DefaultValue)|$($Msg)-【不符合】等级保护标准." -ForegroundColor red
      return $Result
    }

  } elseif ($Operator -eq "ge") {

    if ( $Value -ge $DefaultValue ) {
      $Result =  @{"$($Key)"="[合格项]|$($Value)|$($DefaultValue)|$($Msg)-【符合】等级保护标准."}
      Write-Host "$($Key)"=" [合格项]|$($Value)|$($DefaultValue)|$($Msg)-【符合】等级保护标准." -ForegroundColor White
      return $Result
    } else {
      $Result = @{"$($Key)"="[异常项]|$($Value)|$($DefaultValue)|$($Msg)-【不符合】等级保护标准."}
      Write-Host "$($Key)"=" [异常项]|$($Value)|$($DefaultValue)|$($Msg)-【不符合】等级保护标准." -ForegroundColor red
      return $Result
    }
  }
}

function F_GetRegPropertyValue {
  param (
    [Parameter(Mandatory=$true)][String]$Key,
    [Parameter(Mandatory=$true)][String]$Name,
    [Parameter(Mandatory=$true)][String]$Operator,
    [Parameter(Mandatory=$true)]$DefaultValue,
    [Parameter(Mandatory=$true)][String]$Msg
  )

  try {
    $Value = Get-ItemPropertyValue -Path "Registry::$Key" -ErrorAction Ignore -WarningAction Ignore -Name $Name
    $Result = F_Tools -Key "Registry::$($Name)" -Value $Value -Operator $Operator -DefaultValue $DefaultValue  -Msg $Msg
    return $Result
  } catch {
   $Result = @{"Registry::$($Name)"="[异常项]|$($Key)中$($Name)不存在该项|$($DefaultValue)|$($Msg)"}
   Write-Host $Result.Values -ForegroundColor Red
   return $Result
  }
}

Function F_UrlRequest {
  param (
    [Parameter(Mandatory=$true)][String]$Msrc_api
  )
  Write-Host "[-] $($Msrc_api)" -ForegroundColor Gray
  $Response=Invoke-WebRequest -Uri "$($Msrc_api)"
  Return ConvertFrom-Json -InputObject $Response
}

################################################################################################################################
#
# * 操作系统基础信息记录函数 * #
#
# - 系统信息记录函数 - #
$SysInfo = @{}
# - Get-Computer 命令使用 
# Tips ：在 Server 2019 以及 Windows 10 以下系统无该命令
# $Item = 'WindowsProductName','WindowsEditionId','WindowsInstallationType','WindowsCurrentVersion','WindowsVersion','WindowsProductId','BiosManufacturer','BiosFirmwareType','BiosName','BiosVersion','BiosBIOSVersion','BiosSeralNumber','CsBootupState','OsBootDevice','BiosReleaseDate','CsName','CsAdminPasswordStatus','CsManufacturer','CsModel','OsName','OsType','OsProductType','OsServerLevel','OsArchitecture','CsSystemType','OsOperatingSystemSKU','OsVersion','OsBuildNumber','OsSerialNumber','OsInstallDate','OsSystemDevice','OsSystemDirectory','OsCountryCode','OsCodeSet','OsLocaleID','OsCurrentTimeZone','TimeZone','OsLanguage','OsLocalDateTime','OsLastBootUpTime','CsProcessors','OsBuildType','CsNumberOfProcessors','CsNumberOfLogicalProcessors','OsMaxNumberOfProcesses','OsTotalVisibleMemorySize','OsFreePhysicalMemory','OsTotalVirtualMemorySize','OsFreeVirtualMemory','OsInUseVirtualMemory','OsMaxProcessMemorySize','CsNetworkAdapters','OsHotFixes'
# - Systeminfo 命令使用(通用-推荐)
$Item = 'Hostname','OSName','OSVersion','OSManufacturer','OSConfiguration','OS Build Type','RegisteredOwner','RegisteredOrganization','Product ID','Original Install Date','System Boot Time','System Manufacturer','System Model','System Type','Processor(s)','BIOS Version','Windows Directory','System Directory','Boot Device','System Locale','Input Locale','Time Zone','Total Physical Memory','Available Physical Memory','Virtual Memory: Max Size','Virtual Memory: Available','Virtual Memory: In Use','Page File Location(s)','Domain','Logon Server','Hotfix(s)','Network Card(s)'
Function F_SysInfo {
  # - 当前系统及计算机相关信息 (Primary)
  # Server 2019 以及 Windows 10 适用
  # $Computer = Get-ComputerInfo
  $Computer = systeminfo.exe /FO CSV /S $env:COMPUTERNAME |Select-Object -Skip 1 | ConvertFrom-CSV -Header $Item
  foreach( $key in $Item) {
    $SysInfo += @{"$($key)"=$Computer.$key}
  }
  # - 通用设置针对采用`systeminfo.exe`命令方式
  $SysInfo += @{"WindowsProductName"="$($SysInfo.OSName)"}
  $SysInfo.OsVersion=($Sysinfo.OSVersion -split " ")[0]
  $SysInfo += @{"CsSystemType"=($Sysinfo."System Type" -split " ")[0]}

  # - 当前系统 PowerShell 版本信息以及是否为虚拟机
  $SysInfo += @{"PSVersion"=$PSVersionTable.PSEdition+"-"+$PSVersionTable.PSVersion}

  # - 验证当前计算机产品及其版本 (Primary)
  $Flag = $SysInfo.WindowsProductName -match  "Windows 8.1|Windows 10|Server 2008|Server 2012|Server 2016|Server 2019"
  $ProductName = "$($Matches.Values)"
  if ( $ProductName.Contains("Windows")) {
    $SysInfo += @{"ProductType"="Client"}
    $SysInfo += @{"ProductName"=$ProductName}
    $SysInfo += @{"WindowsVersion"=Get-ItemPropertyValue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseId}
  } else {
    $SysInfo += @{"ProductType"="Server"}
    $SysInfo += @{"ProductName"=$ProductName}
  }

  # - 验证当前计算机产品是是物理机还是虚拟机 (Primary)
  $ComputerType = get-wmiobject win32_computersystem
  if ($ComputerType.Manufacturer -match "VMware"){
    $SysInfo += @{"ComputerType"="虚拟机 - $($ComputerType.Model)"}
  } else {
    $SysInfo += @{"ComputerType"="物理机 - $($ComputerType.Model)"}
  }
  
  # # - 当前计算机温度值信息记录 （WINDOWSERVER2019支持）
  # Get-CimInstance -Namespace ROOT/WMI -Class MSAcpi_ThermalZoneTemperature | % { 
  #   $currentTempKelvin = $_.CurrentTemperature / 10 
  #   $currentTempCelsius = $currentTempKelvin - 273.15 
  #   $currentTempFahrenheit = (9/5) * $currentTempCelsius + 32 
  #   $Temperature += "InstanceName: " + $_.InstanceName+ " ==>> " +  $currentTempCelsius.ToString() + " 摄氏度(C);  " + $currentTempFahrenheit.ToString() + " 华氏度(F) ; " + $currentTempKelvin + "开氏度(K) `n" 
  # }
  # $SysInfo += @{"Temperature"=$Temperature}

  return $SysInfo
}


#
# * - 计算机Mac及IP地址信息函数 * #
#
#  * 系统网络及适配器信息变量 * #
$SysNetAdapter = @{}
function F_SysNetAdapter {
  # - 计算机Mac及IP地址信息
  $Adapter = Get-NetAdapter | Sort-Object -Property LinkSpeed
  foreach ( $Item in $Adapter) {
    $IPAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $Item.ifIndex).IPAddress
    $SysNetAdapter += @{"$($Item.MacAddress)"="$($Item.Status) | $($Item.Name) | $($IPAddress) | $($Item.LinkSpeed) | $($Item.InterfaceDescription)"}
  }
  return $SysNetAdapter
}


#
# * - 计算机系统磁盘与空间剩余查询函数 * #
#
# - 系统磁盘与空间剩余信息 - #
$SysDisk = @{}
function F_SysDisk {
  # - 计算机磁盘信息
  $Disk = Get-Disk
  foreach ( $Item in $Disk) {
    $SysDisk += @{"$($Item.SerialNumber)"="$($Item.Number) | $($Item.FriendlyName) | $($Item.HealthStatus)| $($Item.Size / [math]::Pow(1024,3)) GB | $($Item.PartitionStyle) |$($Item.OperationalStatus)"}
  }
  $Drive = Get-PSDrive -PSProvider FileSystem | Sort-Object -Property Name
  $Drive | % {
    $Free = [Math]::Round( $_.Free / [math]::pow(1024,3),2 )
    $Used = [Math]::Round( $_.Used / [math]::pow(1024,3),2 )
    $Total = [Math]::Ceiling($Free + $Used)
    $SysDisk += @{"FileSystem::$($_.Name)"="$($_.Name) | Free: $($Free) GB | Used: $($Used) GB | Total: $($Total) GB"}
  }
  return $SysDisk
}


#
# * 系统账号检查函数  * #
#
# - 系统账户信息变量 - # 
$SysAccount = @{}
Function F_SysAccount {
  # - 账户检查
  $Account = Get-WmiObject -Class Win32_UserAccount | Select-Object Name,AccountType,Caption,SID
  Write-Host "* 当前系统存在的 $($Account.Length) 名账户 : $($Account.Name)" -ForegroundColor Green
  if($Account.Length -ge 4 -and ($Account.sid  | Select-String -Pattern "^((?!(-500|-501|-503|-504)).)*$")) {
    $Result = @{"SysAccount"="[异常项]-系统中存在其他账号请检查: $($Account.Name)"}
    $SysAccount += $Result
  }else{
    $Result = @{"SysAccount"="[合格项]-系统中无多余其他账号";}
    $SysAccount += $Result
  }
  return $SysAccount
}

#
# * 系统账号策略配置核查函数  * #
#
# - 系统账号策略 - #
$SysAccountPolicy = @{
  # + 密码最短留存期
  "MinimumPasswordAge" = @{operator="le";value=1;msg="密码最短留存期"}
  # + 密码最长留存期
  "MaximumPasswordAge" = @{operator="le";value=90;msg="密码最长留存期"}
  # + 密码长度最小值
  "MinimumPasswordLength" = @{operator="ge";value=14;msg="密码长度最小值"}
  # + 密码必须符合复杂性要求
  "PasswordComplexity" = @{operator="eq";value=1;msg="密码必须符合复杂性要求策略"}
  # + 强制密码历史 N个记住的密码
  "PasswordHistorySize" = @{operator="ge";value=3;msg="强制密码历史个记住的密码"}
  # + 账户登录失败锁定阈值N次数
  "LockoutBadCount" = @{operator="le";value=6;msg="账户登录失败锁定阈值次数"}
  # + 账户锁定时间(分钟)
  "ResetLockoutCount" = @{operator="ge";value=15;msg="账户锁定时间(分钟)"}
  # + 复位账户锁定计数器时间(分钟)
  "LockoutDuration" = @{operator="ge";value=15;msg="复位账户锁定计数器时间(分钟)"}
  # + 下次登录必须更改密码
  "RequireLogonToChangePassword" = @{operator="eq";value=0;msg="下次登录必须更改密码"}
  # + 强制过期
  "ForceLogoffWhenHourExpire" = @{operator="eq";value=0;msg="强制过期"}
  # + 当前管理账号登陆名称
  "NewAdministratorName" = @{operator="ne";value='"Administrator"';msg="当前系统默认管理账号登陆名称策略"}
  # + 当前来宾用户登陆名称
  "NewGuestName" = @{operator="ne";value='"Guest"';msg="当前系统默认来宾用户登陆名称策略"}
  # + 管理员是否被启用
  "EnableAdminAccount" = @{operator="eq";value=1;msg="管理员账户停用与启用策略"}
  # + 来宾用户是否启用
  "EnableGuestAccount" = @{operator="eq";value=0;msg="来宾账户停用与启用策略"}
  # + 指示是否使用可逆加密来存储密码一般禁用(除非应用程序要求超过保护密码信息的需要)
  "ClearTextPassword" = @{operator="eq";value=0;msg="指示是否使用可逆加密来存储密码 (除非应用程序要求超过保护密码信息的需要)"}
  # + 启用时此设置允许匿名用户查询本地LSA策略(0关闭)
  "LSAAnonymousNameLookup" = @{operator="eq";value=0;msg="启用时此设置允许匿名用户查询本地LSA策略 (0关闭)"}
  # + 检查结果存放的空数组
  "CheckResults" = @()
  }
Function F_SysAccountPolicy {
  $Count = $Config.Count
  for ($i=0;$i -lt $Count; $i++){
    $Line = $Config[$i] -split " = "
    if ($SysAccountPolicy.ContainsKey("$($Line[0])")) {
      $Result = F_Tools -Key "SysAccountPolicy::$($Line[0])" -Value $Line[1] -Operator $SysAccountPolicy["$($Line[0])"].Operator -DefaultValue $SysAccountPolicy["$($Line[0])"].Value  -Msg "系统账号策略配置-$($SysAccountPolicy["$($Line[0])"].Msg)"
      $SysAccountPolicy['CheckResults'] += $Result
    }
    if ( $Line[0] -eq "[Event Audit]" ) { break;}
  }
  return $SysAccountPolicy['CheckResults']
}



#
# * 系统事件审核策略配置核查函数  * #
#
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
  # + 检查结果存放的空数组
  CheckResults = @()
}
function F_SysEventAuditPolicy {
  $Count = $Config.Count
  for ($i=0;$i -lt $Count; $i++){
    $Line = $Config[$i] -split " = "
    if ( $Line[0] -eq "[Registry Values]" ) { break;}
    if ($SysEventAuditPolicy.ContainsKey("$($Line[0])")) {
      $Result = F_Tools -Key "SysEventAuditPolicy::$($Line[0])" -Value $Line[1] -Operator $SysEventAuditPolicy["$($Line[0])"].Operator -DefaultValue $SysEventAuditPolicy["$($Line[0])"].Value  -Msg "系统账号策略配置-$($SysEventAuditPolicy["$($Line[0])"].Msg)"
      $SysEventAuditPolicy['CheckResults'] += $Result
    }
  }

  return $SysEventAuditPolicy['CheckResults']
}

#
# * 操作系统用户权限管理策略检查  * #
#
# - 组策略用户权限管理策略 - #
$SysUserPrivilegePolicy = @{
# + 操作系统本地关机策略安全
SeShutdownPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="操作系统本地关机策略"}
# + 操作系统远程关机策略安全
SeRemoteShutdownPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="操作系统远程关机策略"}
# + 取得文件或其他对象的所有权限策略
SeProfileSingleProcessPrivilege = @{operator="eq";value='*S-1-5-32-544';msg="取得文件或其他对象的所有权限策略"}
# + 从网络访问此计算机策略
SeNetworkLogonRight = @{operator="eq";value='*S-1-5-32-544,*S-1-5-32-545,*S-1-5-32-551';msg="从网络访问此计算机策略"}
CheckResults = @()
}

Function F_SysUserPrivilegePolicy {
  # - 策略组用户权限配置
  $Hash = $SysUserPrivilegePolicy.Clone()  # 巨坑之处
  foreach ( $Name in $Hash.keys) {
    if ( $Name.Equals("CheckResults")){ continue; }
    $Line = ($Config | Select-String $Name.toString()) -split " = "
    $Result = F_Tools -Key "SysUserPrivilegePolicy::$($Line[0])" -Value $Line[1] -Operator $SysUserPrivilegePolicy["$($Line[0])"].Operator -DefaultValue $SysUserPrivilegePolicy["$($Line[0])"].Value  -Msg "策略组用户权限配置-$($SysUserPrivilegePolicy["$($Line[0])"].Msg)"
    $SysUserPrivilegePolicy['CheckResults'] += $Result
  }
  return $SysUserPrivilegePolicy['CheckResults']
}

#
# * 操作系统策略组安全选项权限配置检查 * #
# 
# - 组策略安全选项策略 - #
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
  InactivityTimeoutSecs = @{operator="le";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\InactivityTimeoutSecs=4,600";msg="交互式登录-计算机不活动限制值为600秒或更少"}
  # - 交互式登录: 计算机帐户阈值此策略设置确定可导致计算机重启的失败登录尝试次数
  MaxDevicePasswordFailedAttempts = @{operator="le";value="MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\MaxDevicePasswordFailedAttempts=4,10";msg="交互式登录: 此策略设置确定可导致计算机重启的失败登录尝试次数"}
  # - 交互式登录: 试图登录的用户的消息标题
  LegalNoticeCaption = @{operator="eq";value='MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeCaption=1,"安全登陆"';msg="交互式登录: 试图登录的用户的消息标题"}
  # - 交互式登录: 试图登录的用户的消息文本
  LegalNoticeText = @{operator="eq";value='MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeText=7,请谨慎的操作服务器中数据,您所有操作将被记录审计';msg="交互式登录: 试图登录的用户的消息文本"}
  
  # - Microsoft网络客户端: 将未加密的密码发送到第三方 SMB 服务器(禁用)
  EnablePlainTextPassword = @{operator="eq";value="MACHINE\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\EnablePlainTextPassword=4,0";msg="Microsoft网络客户端-将未加密的密码发送到第三方 SMB 服务器(禁用)"}
  # - Microsoft网络服务器：暂停会话前所需的空闲时间数量值为15分钟或更少但不为0
  AutoDisconnect = @{operator="eq";value="MACHINE\System\CurrentControlSet\Services\LanManServer\Parameters\AutoDisconnect=4,15";msg="Microsoft网络服务器-暂停会话前所需的空闲时间数量值为15分钟"}
  
  # - 网络安全: 再下一次改变密码时不存储LAN管理器哈希值(启用)
  NoLMHash = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\NoLMHash=4,1";msg="网络安全-在下一次改变密码时不存储LAN管理器哈希值(启用)"}
  
  # - 网络访问: 不允许SAM账户的匿名枚举值为(启用)
  RestrictAnonymousSAM = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymousSAM=4,1";msg="网络访问-不允许SAM账户的匿名枚举值为(启用)"}
  # - 网络访问:不允许SAM账户和共享的匿名枚举值为(启用)
  RestrictAnonymous = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymous=4,1";msg="网络访问-不允许SAM账户和共享的匿名枚举值为(启用)"}
  
  # - 关机:设置确定是否可以在无需登录 Windows 的情况下关闭计算机(禁用)
  ClearPageFileAtShutdown = @{operator="eq";value="MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management\ClearPageFileAtShutdown=4,0";msg="关机-设置确定是否可以在无需登录 Windows 的情况下关闭计算机(禁用)"}
  
  "CheckResults" = @()
}
Function F_SysSecurityOptionPolicy {
  $Hash = $SysSecurityOptionPolicy.Clone()  # 巨坑之处
  foreach ( $Name in $Hash.keys) {
    if ( $Name.Equals("CheckResults")){ continue; }
    $Flag = $Config | Select-String $Name.toString() 
    $Value = $SysSecurityOptionPolicy["$($Name)"].Value -split ","
    if ( $Flag ) {
      $Line = $Flag -split ","
      $Result = F_Tools -Key "SysSecurityOptionPolicy::$($Name)" -Value $Line[1] -Operator $SysSecurityOptionPolicy["$($Name)"].Operator -DefaultValue $Value[1] -Msg "策略组安全选项配置-$($SysSecurityOptionPolicy["$($Name)"].Msg)"
      $SysSecurityOptionPolicy['CheckResults'] += $Result
    } else {
      $Result = @{"SysSecurityOptionPolicy::$($Name)"="[异常项]|未配置|$($Value[1])|策略组安全选项配置-$($SysSecurityOptionPolicy["$($Name)"].Msg)-【不符合】等级保护标准."}
      $SysSecurityOptionPolicy['CheckResults'] += $Result
    }
  }
  return $SysSecurityOptionPolicy['CheckResults']
}


#
# * 操作系统注册表相关配置检查函数  * #
#
# - 注册表相关安全策略  -
$SysRegistryPolicy = @{
# + 屏幕自动保护程序
ScreenSaveActive = @{regname="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaveActive";operator="eq";value=1;msg="系统基配核查-屏幕自动保护程序策略"}
# + 屏幕恢复时使用密码保护
ScreenSaverIsSecure = @{regname="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaverIsSecure";operator="eq";value=1;msg="系统基配核查-屏幕恢复时使用密码保护策略"}
# + 屏幕保护程序启动时间
ScreenSaveTimeOut = @{regname="HKEY_CURRENT_USER\Control Panel\Desktop";name="ScreenSaveTimeOut";operator="le";value=600;msg="系统基配核查-屏幕保护程序启动时间策略"}

# + 禁止全部驱动器自动播放
DisableAutoplay  = @{regname="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer";name="DisableAutoplay";regtype="DWord";operator="eq";value=1;msg="禁止全部驱动器自动播放"}
NoDriveTypeAutoRun = @{regname="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer";name="NoDriveTypeAutoRun";regtype="DWord";operator="eq";value=255;msg="禁止全部驱动器自动播放"}

# - 检查关闭默认共享盘
restrictanonymous = @{regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa";name="restrictanonymous";operator="eq";value=1;msg="系统网络基配核查-关闭默认共享盘策略"}
restrictanonymoussam = @{regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa";name="restrictanonymoussam";regtype="DWord";operator="eq";value=1;msg="不允许SAM账户的匿名枚举值为(启用)"}

# - 禁用磁盘共享(SMB)
AutoShareWks = @{regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters";name="AutoShareWks";regtype="DWord";operator="eq";value=0;msg="关闭禁用默认共享策略-Server2012"}
AutoShareServer = @{regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters";name="AutoShareServer";regtype="DWord";operator="eq";value=0;msg="关闭禁用默认共享策略-Server2012"}

# - 系统、应用、安全、PS日志查看器大小设置(此处设置默认的两倍配置-建议一定通过日志采集平台采集系统日志比如ELK)
EventlogSystemMaxSize = @{regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\System";name="MaxSize";operator="ge";value=41943040;msg="系统基日志配核查-系统日志查看器大小设置策略"}
EventlogApplicationMaxSize = @{regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Application";name="MaxSize";operator="ge";value=41943040;msg="系统日志基配核查-应用日志查看器大小设置策略"}
EventlogSecurityMaxSize = @{regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Security";name="MaxSize";operator="ge";value=41943040;msg="系统日志基配核查-安全日志查看器大小设置策略"}
EventlogPSMaxSize = @{regname="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Windows PowerShell";name="MaxSize";operator="ge";value=31457280;msg="系统日志基配核查-PS日志查看器大小设置策略"}

# - 防火墙相关操作设置（开启、协议、服务）
DomainEnableFirewall  = @{regname='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile';name='EnableFirewall';regtype="DWord";operator="eq";value=1;msg="开启域网络防火墙"}
StandardEnableFirewall = @{regname='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\StandardProfile';name='EnableFirewall';regtype="DWord";operator="eq";value=1;msg="开启专用网络防火墙"}
PPEnableFirewall = @{regname='HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\PublicProfile';name='EnableFirewall';regtype="DWord";operator="eq";value=1;msg="开启公用网络防火墙"}


# - 结果存储
CheckResults=@()
}
Function F_SysRegistryPolicy { 
  $Registry=  $SysRegistryPolicy.Clone()
  foreach ( $item in $Registry.keys) {
    if ( $item -eq "CheckResults" ){ continue;}
    $Result = F_GetRegPropertyValue -Key $SysRegistryPolicy.$item.regname -Name $SysRegistryPolicy.$item.name -Operator $SysRegistryPolicy.$item.operator -DefaultValue $SysRegistryPolicy.$item.value -Msg $SysRegistryPolicy.$item.msg
    $SysRegistryPolicy['CheckResults'] += $Result
  }
  return $SysRegistryPolicy['CheckResults']
}

#
# * 操作系统服务及运行程序检查函数  * #
#
$SysProcessServicePolicy = @{"CheckResults"=@()}
function F_SysProcessServicePolicy {
  # + 检测系统及用户开机启动项
  $SysAutoStart = Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
  $SysAutoStart.GetValueNames() | % { 
    $res += "$($_)#$($SysAutoStart.GetValue($_)) "
  }
  $Result = @{"SysProcessServicePolicy::SysAutoStart"=$res}
  $SysProcessServicePolicy['CheckResults'] += $Result

  $UserAutoStart = Get-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
  $UserAutoStart.GetValueNames() | % { 
    $res += "$($_)#$($SysAutoStart.GetValue($_)) "
  }
  $Result = @{"SysProcessServicePolicy::UserAutoStart"=$res}
  $SysProcessServicePolicy['CheckResults'] += $Result

  # + 否启用远程桌面服务
  $RDPStatus = (Get-Service -Name "TermService").Status
  # if ($RDP -eq "0" -and $RDPStatus -eq "Running" ) {
  #   $Result = @{"SysProcessServicePolicy::RDPStatus"="当前系统【已启用】远程桌面服务."}
  # } else {
  #   $Result = @{"SysProcessServicePolicy::RDPStatus"="当前系统【未启用】远程桌面服务."}
  # }
  if ($RDPStatus -eq "Running" ) {
    $Result = F_GetRegPropertyValue -Key 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Operator "eq" -DefaultValue 0 -Msg "是否将远程桌面服务禁用"
  } else {
    $Result = @{"SysProcessServicePolicy::RDPStatus"="当前系统【未启用】远程桌面服务."}
  }
  $SysProcessServicePolicy['CheckResults'] += $Result
  # - 否启用NTP服务来同步时钟
  # $NTP = F_GetReg -Key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer' -Name 'Enabled'
  # if ( $NTP -eq "1") {
  #   $Result = @{"SysProcessServicePolicy::NtpServerEnabled"="[合格项]|$NTP|1|系统基础配置核查-启用NTP服务同步时钟策略-【符合】等级保护标准."}
  # } else {
  #   $Result = @{"SysProcessServicePolicy::NtpServerEnabled"="[异常项]|$NTP|1|系统基础配置核查-启用NTP服务同步时钟策略-【不符合】等级保护标准."}
  # }
  $Result = F_GetRegPropertyValue -Key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer' -Name 'Enabled' -Operator "eq" -DefaultValue 1 -Msg "是否启用NTP服务同步时钟策略"
  $SysProcessServicePolicy['CheckResults'] += $Result
  

  # - 是否修改默认的远程桌面端口
  $RDP1 = Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' | % {$_.GetValue("PortNumber")}
  $RDP2 = Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp\' | % {$_.GetValue("PortNumber")} 
  if ( $RDP1 -eq $RDP2 -and $RDP2 -ne "3389") {
    $Result = @{"SysProcessServicePolicy::RDPPort"="[合格项]|$RDP1|除3389以外的端口|系统基础配置核查-默认的远程桌面端口已修改-【符合】等级保护标准."}
  } else {
    $Result = @{"SysProcessServicePolicy::RDPPort"="[异常项]|$RDP1|除3389以外的端口|系统基础配置核查-默认的远程桌面端口未修改-【不符合】等级保护标准."}
  }
  $SysProcessServicePolicy['CheckResults'] += $Result
}


#
# * 操作系统安全检测函数 * 
#
# * 微软Windows服务器安全补丁列表信息 * #
$Msrc_api = "https://api.msrc.microsoft.com/sug/v2.0/zh-CN/affectedProduct?%24orderBy=releaseDate+desc&%24filter=productFamilyId+in+%28%27100000010%27%29+and+severityId+in+%28%27100000000%27%2C%27100000001%27%29+and+%28releaseDate+gt+2020-01-14T00%3A00%3A00%2B08%3A00%29+and+%28releaseDate+lt+2021-05-22T23%3A59%3A59%2B08%3A00%29"
$SysWSUSList = @{}
$SysWSUSListId = @()
$AvailableWSUSList = @{}
function F_SysSecurityPolicy {

  # - 系统补丁验证
  if ( $MsrcUpdate -or ! (Test-Path -Path .\WSUSList.json) ) {
    $MSRC_JSON = F_UrlRequest -Msrc_api $Msrc_api
    $MSRC_JSON.value | % { 
      $id = $_.id;
      $product = $_.product;
      $articleName = $_.kbArticles.articleName | Get-Unique;
      $fixedBuildNumber = $_.kbArticles.fixedBuildNumber | Get-Unique;
      $severity = $_.severity;
      $impact = $_.impact;
      $baseScore = $_.baseScore;
      $cveNumber = $_.cveNumber | Get-Unique;
      $releaseDate = $_.releaseDate
      $SysWSUSList += @{"$($id)"=@{"product"=$product;"articleName"=$articleName;"fixedBuildNumber"=$fixedBuildNumber;"severity"=$severity;"impact"=$impact;"baseScore"=$baseScore;"cveNumber"=$cveNumber;"releaseDate"=$releaseDate}}
    }
    while ($MSRC_JSON.'@odata.nextLink'.length) {
      $MSRC_JSON = F_UrlRequest -Msrc_api $MSRC_JSON.'@odata.nextLink'
      $MSRC_JSON.value | % { 
        $id = $_.id;
        $product = $_.product;
        $articleName = $_.kbArticles.articleName | Get-Unique;
        $fixedBuildNumber = $_.kbArticles.fixedBuildNumber | Get-Unique;
        $severity = $_.severity;
        $impact = $_.impact;
        $baseScore = $_.baseScore;
        $cveNumber = $_.cveNumber | Get-Unique;
        $releaseDate = $_.releaseDate
        $SysWSUSList += @{"$($id)"=@{"product"=$product;"articleName"=$articleName;"fixedBuildNumber"=$fixedBuildNumber;"severity"=$severity;"impact"=$impact;"baseScore"=$baseScore;"cveNumber"=$cveNumber;"releaseDate"=$releaseDate }}
      }
    }
    Write-Host "[-] 已从 Microsoft 安全响应中心获取更新 $($MSRC_JSON.'@odata.count') 条补丁信息!" -ForegroundColor Green
    Write-Host "[-] 正在将获取的更新 $($MSRC_JSON.'@odata.count') 条补丁信息写入到本地 WSUSList.json 文件之中!" -ForegroundColor Green
    $SysWSUSList | ConvertTo-Json | Out-File WSUSList.json -Encoding utf8
    $SysWSUSListId = $SysWSUSList.keys
    $SysWSUSList.keys | ConvertTo-Json | Out-File WSUSListId.json -Encoding utf8
  } else {
    # 从本地读取JSON文件存储的补丁信息。
    if (Test-Path -Path .\WSUSList.json) {
      $SysWSUSList = Get-Content -Raw -Encoding UTF8 .\WSUSList.json | ConvertFrom-Json
      $SysWSUSListId  = Get-Content -Raw -Encoding UTF8 .\WSUSListId.json | ConvertFrom-Json
      Write-Host "[-] 已从本地 WSUSList.json 文件获得 $($SysWSUSListId.count) 条补丁信息!" -ForegroundColor Green
    } else {
      Write-Host "[-] 本地未能找到存放补丁信息的 WSUSList.json 文件! 请采用 -Update True 标记从Microsoft 安全响应中心获取更新" -ForegroundColor Red
      break
      exit
    }
  }
 
  # 获取当前系统版本可用的补丁列表
  $AvailableWSUSListId = @() 
  if ($SysInfo.ProductType -eq "Client") {
    Write-Host "[-] Desktop Client" -ForegroundColor Gray
    foreach ($KeyName in $SysWSUSListId) {
      if(($SysWSUSList."$KeyName".product -match $SysInfo.ProductName) -and ($SysWSUSList."$KeyName".product -match $SysInfo.WindowsVersion) -and ($SysWSUSList."$KeyName".product -match ($SysInfo.CsSystemType -split " ")[0])) {
        if (($SysWSUSList."$KeyName".fixedBuildNumber -match $SysInfo.OsVersion) -or ($SysWSUSList."$KeyName".fixedBuildNumber.length -eq 0 )) {
          $AvailableWSUSList."$KeyName" = $SysWSUSList."$KeyName"
          $AvailableWSUSListId += "$KeyName"
        }
      }
    }
  } else {
    Write-Host "[-] Windows Server" -ForegroundColor Gray
    foreach ($KeyName in $SysWSUSListId) {
      if(($SysWSUSList."$KeyName".product -match $SysInfo.ProductName) -and ($SysWSUSList."$KeyName".product -match $SysInfo.ProductName)) {
        $AvailableWSUSList."$KeyName" = $SysWSUSList."$KeyName"
        $AvailableWSUSListId += "$KeyName"
      }
    }
  }
  Write-Host $SysInfo.ProductName $SysInfo.WindowsVersion ($SysInfo.CsSystemType -split " ")[0] $SysInfo.OsVersion
  Write-Host "[-] 已从梳理出适用于当前 $($SysInfo.ProductType) 系统版本的 $($AvailableWSUSList.count) 条补丁信息!`n" -ForegroundColor Green

  # 已安装的补丁
  $InstallWSUSList = @{}
  $msg = @()
  foreach ($id in $AvailableWSUSListId) {
    if( $SysInfo.'Hotfix(s)' -match $AvailableWSUSList."$id".articleName ) {
      $InstallWSUSList."$id" = $SysWSUSList."$id"
      $msg += "[+]" + $SysWSUSList."$id".product + $SysWSUSList."$id".fixedBuildNumber + " " +  $SysWSUSList."$id".articleName + "(" + $SysWSUSList."$id".cveNumber   + ")" + $SysWSUSList."$id".severity  + $SysWSUSList."$id".baseScore + "`n"
    } 
  }
  Write-Host "[-] $($SysInfo.'Hotfix(s)') ，共 $($AvailableWSUSList.count) 条漏洞补丁信息!`n$($msg)" -ForegroundColor Green

  # 未安装的补丁
  $NotInstallWSUSList = @{}
  $msg = @()
  foreach ($id in $AvailableWSUSListId) {
    if(-not($InstallWSUSList."$id")) {
     $NotInstallWSUSList."$id" = $SysWSUSList."$id"
     $msg += "[+]" + $SysWSUSList."$id".product + $SysWSUSList."$id".fixedBuildNumber + " " + $SysWSUSList."$id".articleName + "(" + $SysWSUSList."$id".cveNumber + ")" + $SysWSUSList."$id".severity + $SysWSUSList."$id".baseScore + "`n"
    }
  }
  Write-Host "[-] 未安装 $($NotInstallWSUSList.count) 条漏洞补丁信息，共 $($AvailableWSUSList.count) 条漏洞补丁信息!`n$($msg)" -ForegroundColor red
}

#
# * 杂类检测函数 * 
#
$OtherCheck = @{}
function F_OtherCheckPolicy {
  # - 当前系统已安装的软件
  $Product = Get-WmiObject -Class Win32_Product | Select-Object -Property Name,Version,IdentifyingNumber | Sort-Object Name | Out-String
  $OtherCheck += @{"Product"="$($Product)"}

  # - 当前系统最近访问文件或者目录
  $Recent = (Get-ChildItem ~\AppData\Roaming\Microsoft\Windows\Recent).Name
  $OtherCheck += @{"Recent"="$($Recent)"}
  return $OtherCheck
}


function Main() {
<#
.SYNOPSIS
main 函数程序执行入口
.DESCRIPTION
调用上述编写的相关检测脚本
.EXAMPLE
main
#>

$ScanStartTime = Get-date -Format 'yyyy-M-d H:m:s'
F_Logging -Level Info -Msg "#################################################################################"
F_Logging -Level Info -Msg "- @Desc: Windows Server 安全配置策略基线检测脚本  [将会在Github上持续更新-star]"
F_Logging -Level Info -Msg "- @Author: WeiyiGeek"
F_Logging -Level Info -Msg "- @Blog: https://www.weiyigeek.top"
F_Logging -Level Info -Msg "- @Github: https://github.com/WeiyiGeek/SecOpsDev/tree/master/OS-操作系统/Windows"
F_Logging -Level Info -Msg "#################################################################################`n"

F_Logging -Level Info -Msg "[*] Windows Server 安全配置策略基线检测脚本已启动."
F_Logging -Level Info -Msg "[*] 脚本执行: $($Executor), 是否在线拉取微软安全中心的服务器安全补丁列表信息: $($MsrcUpdate)`n"
# 1.判断当前运行的powershell终端是否管理员执行
F_Logging -Level Info -Msg "[-] 正在检测当前运行的PowerShell终端是否管理员权限...`n"
$flag = F_IsCurrentUserAdmin
if (!($flag)) {
  F_Logging -Level Error -Msg "[*] 脚本执行发生错误,请使用管理员权限运行该脚本..例如: Start-Process powershell -Verb runAs...."
  F_Logging -Level Warning -Msg "[*] 正在退出执行该脚本......"
  return
}
F_Logging -Level Info -Msg "[*] PowerShell 管理员权限检查通过...`n"

# 2.当前系统策略配置文件导出 (注意必须系统管理员权限运行) 
F_Logging -Level Info -Msg "[-] 正在导出当前系统策略配置文件 config.cfg......`n"
secedit /export /cfg config.cfg /quiet
start-sleep 3
if ( -not(Test-Path -Path config.cfg)) {
  F_Logging -Level Error -Msg "[*] 当前系统策略配置文件 config.cfg 不存在,请检查......`n"
  F_Logging -Level Warning -Msg "[*] 正在退出执行该脚本......"
  return
} else { 
  Copy-Item -Path config.cfg -Destination config.cfg.bak -Force
}
$Config = Get-Content -path config.cfg

# 3.系统相关信息以及系统安全组策略检测
F_Logging -Level Info -Msg "[-] 当前系统信息一览"
$SysInfo = F_SysInfo
$SysInfo

F_Logging -Level Info -Msg "[-] 当前系统网络信息一览"
$SysNetAdapter = F_SysNetAdapter
$SysNetAdapter

F_Logging -Level Info -Msg "[-] 当前系统磁盘信息一览"
$SysDisk = F_SysDisk
$SysDisk

F_Logging -Level Info -Msg "[-] 当前系统账户信息一览"
$SysAccount = F_SysAccount
$SysAccount

F_Logging -Level Info -Msg "[-] 当前系统安全策略信息一览"
$SysAccountPolicy.CheckResults = F_SysAccountPolicy
$SysEventAuditPolicy.CheckResults = F_SysEventAuditPolicy
$SysUserPrivilegePolicy.CheckResults = F_SysUserPrivilegePolicy
$SysSecurityOptionPolicy.CheckResults = F_SysSecurityOptionPolicy
$SysRegistryPolicy.CheckResults = F_SysRegistryPolicy
$SysProcessServicePolicy.CheckResults = F_SysProcessServicePolicy

F_Logging -Level Info -Msg "[-] 当前系统杂类信息一览"
$OtherCheck = F_OtherCheckPolicy
$OtherCheck.Values

F_Logging -Level Info -Msg "[-] 当前系统安全补丁情况信息一览"
F_SysSecurityPolicy

# 4.程序执行完毕
$ScanEndTime = Get-date -Format 'yyyy-M-d H:m:s'
F_Logging -Level Info -Msg "- Windows Server 安全配置策略基线检测脚本已执行完毕......`n开始时间：${ScanStartTime}`n完成时间: ${ScanEndTime}"
}

Main


