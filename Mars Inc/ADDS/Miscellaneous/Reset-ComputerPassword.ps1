Function Reset-ADComputerMachinePassword {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $computers = Import-Csv -Path "C:\Users\abelraf\OneDrive - Mars Inc\Documents\Identity Team\Projects\ADDS\PingCastle reports\computerpasswordlastset Mars-AD by LastLogonTimeStamp.csv"
    $cred = Get-Credential

    Foreach ($computer in $computers) {
        Invoke-Command -ComputerName $computer.Name -ScriptBlock { Reset-ComputerMachinePassword -Credential $using:cred }
    }
}

