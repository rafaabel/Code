Import-Module ActiveDirectory

$computerLastLogonTimeStamps = @()
$computers = Import-Csv -Path "C:\Users\abelraf\OneDrive - Mars Inc\Documents\Identity Team\Projects\ADDS\PingCastle reports\computerpasswordlastset Mars-AD by No VDIs.csv"

Foreach ($computer in $computers) {
    $ADComputer = Get-ADComputer -Identity $computer.DistinguishedName -Properties * | Select-Object Name, LastLogonTimeStamp, OperatingSystem
    $computerLastLogonTimeStamps += New-Object PsObject -Property @{
        Name               = $ADComputer.Name
        LastLogonTimeStamp = w32tm.exe /ntte $ADComputer.LastLogonTimeStamp
        OperatingSystem    = $ADComputer.OperatingSystem
    }
}

$computerLastLogonTimeStamps | Export-Csv -Path "C:\Users\abelraf\OneDrive - Mars Inc\Documents\Identity Team\Projects\ADDS\PingCastle reports\computerpasswordlastset Mars-AD by LastLogonTimeStamp.csv" -NoTypeInformation
