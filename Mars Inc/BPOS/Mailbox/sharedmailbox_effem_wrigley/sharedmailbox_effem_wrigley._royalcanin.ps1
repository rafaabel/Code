#Clear Variables

$log1 = $null
$log2 = $null
$log3 = $null
$log4 = $null
$file = $null
$import = $null
$accountnamefind = $null 
$samaccountnamefind  = $null
$accountmailfind = $null 
$accountnameverification = $null
$samaccountnameverification = $null
$accountmailverificaiton = $null

cls

#Connection to ARS

$cred = Get-Credential
Connect-QADService -proxy vmww4618.mars-ad.net -Credential $cred 

#Function to choose the .csv file via open file dialog

Function Get-FileName

{
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null 
$OpenFileDialog= New-Object system.windows.forms.openfiledialog
$OpenFileDialog.InitialDirectory = "C:\"
$OpenFileDialog.filter = "CSV (*.csv)| *.csv"
$OpenFileDialog.showdialog() | Out-Null
$OpenFileDialog.filenames
}

#Select the .csv file

   Write-host "================== Shared Mailbox Creation =================="
   Write-host "Please select the .csv file. Then press Enter to continue" 
   Write-host 
   Pause
   Write-host

cls

$file= Get-FileName 
$import =  Import-CSV $file  -Delimiter ',' 
$array = $import.mail -split "@"

#Ask and verify if email address and name exists or if they contain special characters

Do { 

$import| ForEach-Object {
$accountnamefind = Get-QADUser $_.name | select name  
$samaccountnamefind  = Get-QADUser $_.samaccountname | select samaccountname
$accountmailfind = Get-QADUser $_.mail | select mail 

$accountnameverification = $_.name 
$samaccountnameverification = $_.samaccountname
$accountmailverificaiton = $_.mail 


 If (($accountnamefind -ne $null) -or ($samaccountnamefind -ne $null) -or ($accountmailfind -ne $null)) {
        Write-host
        $log1 = "One email address or name for $($_.name) already exists in Active Directory and cannot be created. Please check your .csv file." 
        Write-host  $log1
        $log1 |  out-file -FilePath C:\Temp\LogSMBscript.txt -append
        Write-host "Log saved in C:\Temp\LogSMBscript.txt "
        pause
        exit
        Write-host 
    }

    ElseIf (($accountnameverification -match '[^\p{L}\p{Nd}/_/./-]') -or ($samaccountnameverification -match'[^\p{L}\p{Nd}/_/./-]') -or ($accountmailverification -match'[^\p{L}\p{Nd}/_/./-]')) {
        Write-host
        $log2 = "One email address or name for $($_.name) contains special characters. Please check your .csv file." 
        Write-host $log2
        $log2 |  out-file -FilePath C:\Temp\LogSMBscript.txt -append
        Write-host "Log saved in C:\Temp\LogSMBscript.txt "
        pause
        exit
        Write-host
    }

    ElseIf ($samaccountnameverification.length -gt 20) {
        Write-host
        $log3 = "SamAccountName $($_.samaccountname) contains more than 20 characters.  Please check your .csv file." 
        Write-host $log3
        $log3 |  out-file -FilePath C:\Temp\LogSMBscript.txt -append
        Write-host "Log saved in C:\Temp\LogSMBscript.txt"
        pause
        exit
        Write-host 
    }

    Else {
        Write-host 
        $log4 = "Email address and name for $($_.name) is valid" 
        Write-host $log4
        $log4 |  out-file -FilePath C:\Temp\LogSMBscript.txt -append 
        Write-host "Log saved in C:\Temp\LogSMBscript.txt"
        Write-host
    }
   }
}

While (($accountnamefind -ne $null) -or ($samaccountnamefind -ne $null) -or ($accountmailfind -ne $null) -or ($accountnameverification  -match '[^\p{L}\p{Nd}/_/./-]') -or ($samaccountnameverification -match'[^\p{L}\p{Nd}/_/./-]')-or ($accountmailverification  -match'[^\p{L}\p{Nd}/_/./-]') -or ($samaccountnameverification.length -gt 20))

#Creation of shared mailbox

If ($array[1] -eq "effem.com") {
    write-host "Creating @effem.com shared mailboxes..."
    write-host 
    $import | ForEach-Object { 
        New-QADUser -Name $_.Name.trim()`
                    -DisplayName $_.DisplayName`                    -SamAccountName  $_.SamAccountName.trim()`                    -UserPrincipalName $_.mail.trim()`
                    -Email $_.mail.trim()`
                    -ParentContainer "OU=Shared Mailboxes,OU=Mars,OU=Exchange,OU=IT-Services,DC=Mars-AD,DC=Net"`
                    -UserPassword (Get-Random)`
                    -objectAttributes @{targetaddress = "smtp:"+$_.SamAccountName.trim()+"@mars.onmicrosoft.com"; mailnickname  = $_.SamAccountName.trim(); extensionAttribute8 = $_.extensionAttribute8.trim(); extensionAttribute10 = $_.extensionAttribute10.trim();  extensionAttribute11 = $_.extensionAttribute11.trim();  extensionAttribute12 = $_.extensionAttribute12.trim(); proxyAddresses = "SMTP:"+$_.mail.trim()}

        Set-QADUser -Identity $_.Name.trim()`
                    -objectAttributes @{proxyAddresses=@{Append="smtp:"+$_.SamAccountName.trim()+"@mars.onmicrosoft.com"}}
    }
}
Elseif ($array[1] -eq "wrigley.com") {
    write-host "Creating @wrigley.com shared mailboxes..." 
    write-host 
    $import | ForEach-Object { 
        New-QADUser -Name $_.Name.trim()`                    -DisplayName  $_.DisplayName`                    -SamAccountName $_.SamAccountName.trim()`                    -UserPrincipalName $_.mail.trim()`                    -Email $_.mail.trim()`                    -ParentContainer "OU=Shared Mailboxes,OU=Wrigley,OU=Exchange,OU=IT-Services,DC=Mars-AD,DC=Net"`                    -UserPassword (Get-Random)`                    -objectAttributes @{targetaddress = "smtp:"+$_.SamAccountName.trim()+"@mars.onmicrosoft.com"; mailnickname  = $_.SamAccountName.trim(); extensionAttribute8 = $_.extensionAttribute8.trim(); extensionAttribute10 = $_.extensionAttribute10.trim();  extensionAttribute11 = $_.extensionAttribute11.trim(); extensionAttribute12 = $_.extensionAttribute12.trim(); proxyAddresses ="SMTP:"+$_.mail.trim()}

        Set-QADUser -Identity $_.Name.trim()`
                    -objectAttributes @{proxyAddresses=@{Append="smtp:"+$_.SamAccountName.trim()+"@mars.onmicrosoft.com"}}
    }
}

Elseif ($array[1] -eq "royalcanin.com") {
    write-host "Creating @royalcanin.com shared mailboxes..." 
    write-host 
    $import | ForEach-Object { 
        New-QADUser -Name $_.Name.trim()`                    -DisplayName  $_.DisplayName`                    -SamAccountName $_.SamAccountName.trim()`                    -UserPrincipalName $_.mail.trim()`                    -Email $_.mail.trim()`                    -ParentContainer "OU=Shared Mailboxes,OU=Royal Canin,OU=Exchange,OU=IT-Services,DC=Mars-AD,DC=Net"`                    -UserPassword (Get-Random)`                    -objectAttributes @{targetaddress = "smtp:"+$_.SamAccountName.trim()+"@mars.onmicrosoft.com"; mailnickname  = $_.SamAccountName.trim(); extensionAttribute8 = $_.extensionAttribute8.trim(); extensionAttribute10 = $_.extensionAttribute10.trim();  extensionAttribute11 = $_.extensionAttribute11.trim(); extensionAttribute12 = $_.extensionAttribute12.trim(); proxyAddresses ="SMTP:"+$_.mail.trim()}

        Set-QADUser -Identity $_.Name.trim()`
                    -objectAttributes @{proxyAddresses=@{Append="smtp:"+$_.SamAccountName.trim()+"@mars.onmicrosoft.com"}}
    }
}
    
Else {

Write-Host "Domain name for $($_.mail) is not correct. Please check the sheet and choose @effem.com, @wrigley.com or @royalcanin.com in mail column. Shared mailbox not created."
pause
cls

}

Write-host
Write-host 'Script completed!' 

