##############################################################################################################
# Author�� WeiyiGeek
# Description����Powershell��ʹ��PSFTPģ�������ʵ��FTP�������ļ��ϴ�
# Date�� 2023��2��23�� 12:55:46
# Blog�� https://blog.weiyigeek.top
# Wechat��WeiyiGeeker
# ��ӭ��ע���ں�: ȫջ����ʦ����ָ��
##############################################################################################################
$AuthorSite = "https://www.weiyigeek.top"
$Flag = 0
$Last_db_name = ""                       # ��ȡ����ϴ��ı����ļ�����
$Last_record_file = "./upload.txt"       # ��¼FTP�ϴ��ɹ��ı����ļ�
$LocationBackupDir = "F:\WeiyiGeek"  # ���ر���Ŀ¼
$Current_db_name = (get-childitem $LocationBackupDir | sort CreationTime -Descending |  Select-Object -First 1).name # ��ȡ�������ɵı����ļ�
$FTPConnect = "ftp://10.20.176.215:30021"  # FTP �����������ַ���
$FTPUser = "dwBlAGkAeQBpAGcAZQBlAGsA"      # base64 ����
$FTPPass = "cABhAHMAcwB3AG8AcgBkAA=="      # base64 ����
$FTPDir = "/weiyigeek"

# �������
function CheckRequipment() {
  if (-not(Get-Module -ListAvailable PSFTP)) {
   Write-host "[$(Date)] ��ǰϵͳ�в����� PSFTP ģ�飬���ڹ���ԱȨ�������� Install-Module -Name PSFTP ����" -ForegroundColor Red  
   $res=$(Read-Host "[$(Date)] �Ƿ�ִ�а�װPSFTPģ������[Y/N]?")
   if ( $res -eq "Y" ) {
    Install-Module -Name PSFTP 
   } else {
    Write-host "[$(Date)] ���ֶ��ڹ���ԱȨ�������� Install-Module -Name PSFTP ����" -ForegroundColor Red  
    Exit -1
   }
  } else {
   Write-host "[$(Date)] �ű��������ͨ��...." -ForegroundColor Green  
  }
}

# ����ת��
function Convert($string) {
   $bytes  = [System.Convert]::FromBase64String($string);
   $decoded = [System.Text.Encoding]::Unicode.GetString($bytes); 
   return $decoded;
}

# �ϴ�����
function Upload($file_name,$ftp_user,$ftp_pass) {
   # ��������Ʊ��
   $FTPCre = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ftp_user, $ftp_pass

   # ����ftp����������&������״̬
   (Set-FTPConnection -Credentials $FTPCre -Server $FTPConnect -UsePassive).WelcomeMessage

   # �ϴ�ָ���ļ�
   try {
       Send-FTPItem -LocalPath $LocationBackupDir\${file_name} -Path $FTPDir -Overwrite
       Write-Host "[$(Date)] Upload Status: $($response.StatusDescription)`nUpload File $FTPDir/$file_name successful! " -ForegroundColor Green  
    } catch {
        Write-Host "[$(Date)] Upload File $FTPConnectRemoteDir/$db_name Faild!" -ForegroundColor Red
    } finally {
       Exit-PSSession 
    }
}

# �������
function main () {
    if (-not(Test-Path $Last_record_file)) {
        start $AuthorSite
        CheckRequipment
        Write-host "[$(Date)] �״����б��ݽű����������� $Last_record_file �ı��ļ�!" -ForegroundColor Green
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

    Out-File -FilePath ./logs.txt -InputObject "[$(Date)] ����ִ�У���ǰ�ϴ���ʶ $Flag . " -Encoding utf8 -Append

    if ( $Flag -ne 0 ) {
        Write-host "[$(Date)] ��ǰ���ݿⱸ���ļ� $Current_db_name ��д�� $Last_record_file �ļ���!" -ForegroundColor Green  
        Out-File -FilePath $Last_record_file -InputObject $Current_db_name -Encoding ASCII -Append
        $logs = "[$(Date)] ��ǰ���ݿⱸ���ļ� $Current_db_name , �ϴ����ݿⱸ���ļ� $Last_db_name ����, �ϴ���ʶ $Flag ."
        Write-host $logs -ForegroundColor Green  
        Out-File -FilePath ./logs.txt -InputObject $logs -Encoding utf8 -Append
        $FTPPassword = ConvertTo-SecureString -String $(Convert($FTPPass)) -AsPlainText -Force
        Upload -file_name $Current_db_name -ftp_user $(Convert("$FTPUser ")) -ftp_pass $FTPPassword
    }
}

main

