###########################################################################
# Author: WeiyiGeek
# Description: ʹ��Powershell��Windowsԭ��ftp�ͻ��˹���(����֧������ģʽ)�����ļ�����.
# Date: 2023��2��23�� 12:55:46
# Blog: https://blog.weiyigeek.top
# ��ӭ��ע���ں�: ȫջ����ʦ����ָ��
###########################################################################
$AuthorSite = "https://www.weiyigeek.top"
$Flag = 0
$Last_db_name = ""                    # ��ȡ����ϴ��ı����ļ�����
$Last_record_file = "./upfile.txt"    # ��¼FTP�ϴ��ɹ��ı����ļ�
$LocationBackupDir = "F:\weiyigeek\"  # ���ر����ļ���ŵ�Ŀ¼
$Current_db_name = (get-childitem $LocationBackupDir | sort CreationTime -Descending |  Select-Object -First 1).name
$FTPConnect = "open 192.168.1.12 21"  # FTP������IP����˿�
$FTPUser = "VwBlAGkAeQBpAEcAZQBlAGsA" # base64 ����
$FTPPass = "UABhAHMAcwB3AG8AcgBkAA==" # base64 ����
$FTPRemoteDir = "/ftp/weiyigeek.top/" # �洢�����ļ���Զ��Ŀ¼ 

function Convert($string) {
   $bytes  = [System.Convert]::FromBase64String($string);
   $decoded = [System.Text.Encoding]::Unicode.GetString($bytes); 
   return $decoded;
}

if (-not(Test-Path $Last_record_file)) {
  start $AuthorSite 
  Write-host "[$(Date)] �״����б��ݽű����������� $Last_record_file �ı��ļ�!" -ForegroundColor Green
  Out-File -FilePath $Last_record_file -InputObject $Current_db_name -Encoding ASCII -Append
  Start-Process -FilePath $AuthorSite
  $Last_db_name = Get-Content -Tail 1 $Last_record_file
  $Flag = 1
} else {
  $Last_db_name = Get-Content -Tail 1 $Last_record_file
  Write-host "[$(Date)] ��ǰ���� $Current_db_name ���ݿⱸ���ļ�������д�� $Last_record_file �ļ���!" -ForegroundColor Green  
  Out-File -FilePath $Last_record_file -InputObject $Current_db_name -Encoding ASCII -Append
  if ( $Current_db_name -eq $Last_db_name) {
   $Flag = 0
  } else {
   $Flag = 1
  }
}

Write-host "[$(Date)] ��ǰ���� $Current_db_name , ǰһ�����ݿⱸ���ļ� $Last_db_name ����, ��ʶ $Flag" -ForegroundColor Green  
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



