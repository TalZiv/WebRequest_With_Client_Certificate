Function ExitWithCode([Int]$ExitCode){
$Host.SetShouldExit($ExitCode)
exit
}
 
#[System.Net.ServicePointManager]::Expect100Continue = {$true}
#[System.Net.ServicePointManager]::SecurityProtocol = 'Ssl3'
#[System.Net.ServicePointManager]::SecurityProtocol = 'TLS'

#Configuration Section

# web endpoint
$URL = "CHANGE_ME" 

# XML data to send
$PostData = @"CHANGE_ME" 

# thumbprint of the certificate to use from LOCAL MACHINE personal keystore
$cert = dir Cert:\LocalMachine\My | ? { $_.Thumbprint -eq "CHANGE_ME"} | Select-Object -First 1 
 
[net.httpWebRequest] $webRequest = [Net.WebRequest]::Create($URL)
$webRequest.Headers.Add("SOAPAction", $URL)
 
$webRequest.ContentType = 'application/soap+xml charset=utf-8'
$webRequest.KeepAlive = $false
$webRequest.Method = 'POST'
$webRequest.Timeout = 120000
 
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
 
$webRequest.UseDefaultCredentials = $true
$webRequest.PreAuthenticate = $true
 
If ($LogLevel -eq 1)
{
     write-host "Certificate Porperties, Correct certificate is selected:`n$CertDetails"
     $cert |Format-List -Property *
     echo "#---- Certificate Details ----#" >> $LogFile
     $cert |Format-List -Property *|Out-File $LogFile -Append
}
    
$webRequest.ClientCertificates.add($cert)
$enc = [System.Text.Encoding]::GetEncoding('utf-8')
 
[byte[]]$bytes = $enc.GetBytes($PostData)
 
$webRequest.ContentLength = $bytes.Length
 
If ($LogLevel -eq 1)
{
     $webrequest |Format-List -Property *
     echo "#---- Web Request Detailes ----#" >> $LogFile
     $webrequest |Format-List -Property *|Out-File $LogFile -Append
}
 
try
{
     [System.IO.Stream]$reqStream = $webRequest.GetRequestStream()
}
catch [System.Net.WebException]
{
     $ExceptionMessage = $_.Exception.Message  
     Write-Host "Error: $ExceptionMessage`nERROR - Web request failed" -ForegroundColor red
     ExitWithCode(1)
}
 
#$reqStream
$reqStream.Write($bytes, 0, $bytes.Length)
$reqStream.Close()
 
[net.httpWebResponse] $webResponse = $webRequest.GetResponse()
#$webResponse.StatusCode.value__
 
 
$responseStream = $webResponse.GetResponseStream()
$sr = New-Object IO.StreamReader($responseStream)
$result = $sr.ReadToEnd()
   
If ($LogLevel -eq 1)
{
     write-host "$result"
     echo "#---- Response Detailes ----#" >> $LogFile
     $result |Out-File $LogFile -Append
}
 
[xml]$Global:ResponseXML = $result