Import-Module ActiveDirectory

$computerLastLogonTimeStamps = @()
$computers = Import-Csv -Path "C:\path\file.csv"

Foreach ($computer in $computers) {
    $ADComputer = Get-ADComputer -Identity $computer.DistinguishedName -Properties * | Select-Object Name, LastLogonTimeStamp, OperatingSystem
    $computerLastLogonTimeStamps += New-Object PsObject -Property @{
        Name               = $ADComputer.Name
        LastLogonTimeStamp = w32tm.exe /ntte $ADComputer.LastLogonTimeStamp
        OperatingSystem    = $ADComputer.OperatingSystem
    }
}

$computerLastLogonTimeStamps | Export-Csv -Path "C:\path\file.csv" -NoTypeInformation
