##############################################################################################################
# Author: WeiyiGeek
# Description: ʹ��Powershell��.NET�����õ�FTP������ System.Net.FtpWebRequest����ftp�����������б����ļ��ϴ�.
# Date: 2023��2��23�� 12:55:46
# Blog: https://blog.weiyigeek.top
# ��ӭ��ע���ں�: ȫջ����ʦ����ָ��
##############################################################################################################
$AuthorSite = "https://www.weiyigeek.top"
$Flag = 0
$Last_db_name = ""
$Last_record_file = "./upload.txt"
$LocationBackupDir = "F:\weiyigeek.top"
$Current_db_name = (get-childitem $LocationBackupDir | sort CreationTime -Descending |  Select-Object -First 1).name
$FTPConnectRemoteDir = "ftp://192.168.1.12/ftp/weiyigeek.top/"  # FTP �����������ַ���
$FTPUser = "VwBlAGkAeQBpAEcAZQBlAGsA" # base64 ����
$FTPPass = "UABhAHMAcwB3AG8AcgBkAA==" # base64 ����

function Convert($string) {
   $bytes  = [System.Convert]::FromBase64String($string);
   $decoded = [System.Text.Encoding]::Unicode.GetString($bytes); 
   return $decoded;
}

function Upload($file_name,$ftp_user,$ftp_pass) {
    # Create Request Connect FTP Server Strings and NetworkCredential
    $request =  [System.Net.FtpWebRequest]([System.net.WebRequest]::Create("$FTPConnectRemoteDir/$file_name"))
    $request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
    $request.Credentials = New-Object System.Net.NetworkCredential($ftp_user,$ftp_pass)

    # Enable SSL for FTPS. Should be $false if FTP.
    $request.EnableSsl = $false;

    # Write the file to the request object.
    $fileBytes = [System.IO.File]::ReadAllBytes("$LocationBackupDir/$file_name")
    $request.ContentLength = $fileBytes.Length;
    $requestStream = $request.GetRequestStream()

    # �ϴ��ļ�
    try {
        Write-host "[$(Date)] Upload To $FTPConnectRemoteDir/$file_name ." -ForegroundColor Green  
        $requestStream.Write($fileBytes, 0, $fileBytes.Length)
    } finally {
        $requestStream.Dispose()
    }

    # �����Ӧ
    try {
        $response = [System.Net.FtpWebResponse]($request.GetResponse())
        Write-Host "[$(Date)] Upload Status: $($response.StatusDescription)`nUpload File $FTPConnectRemoteDir/$file_name successful! " -ForegroundColor Green  
    } catch {
        Write-Host "[$(Date)] Upload File $FTPConnectRemoteDir/$db_name Faild!" -ForegroundColor Red
    } finally {
        if ($null -ne $response) {
            $response.Close()
        }
    }
}


if (-not(Test-Path $Last_record_file)) {
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
    Upload -file_name $Current_db_name -ftp_user $(Convert("$FTPUser ")) -ftp_pass $(Convert("$FTPPass"))
}

