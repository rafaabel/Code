$cred = Get-Credential
Connect-QADService -proxy vmww4618.mars-ad.net -Credential $cred 

$import = Import-CSV "C:\Scripts\Turin_Script\All_Turin_Users_2.csv" -delimiter ','
$import | ForEach-Object {
Set-QADUser $_.marsADID -mail $_.marsPreviousSMTPAddress -objectAttributes @{ProxyAddresses= "SMTP:"+$_.marsPreviousSMTPAddress}
Set-QADUser $_.marsADID -objectAttributes @{ProxyAddresses=@{Append= "smtp:"+$_.mail}}
} 

