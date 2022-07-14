Function Reset-ADComputerMachinePassword {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $computers = Import-Csv -Path "C:\Users\abelraf\OneDrive - Mars Inc\Documents\Identity Team\Projects\ADDS\PingCastle reports\computerpasswordlastset Mars-AD by LastLogonTimeStamp.csv"
    $localadmincred = Get-Credential
    $domaincred = Get-Credential


    Foreach ($computer in $computers) {
        Invoke-Command -ComputerName $computer.Name -Credential $using:localadmincred -ScriptBlock { Reset-ComputerMachinePassword -Credential $using:domaincred }
    }
}


$localCredential = New-Object System.Management.Automation.PSCredential -ArgumentList "domain\user", (ConvertTo-SecureString -String "password" -AsPlainText -Force)
$domainCredential = New-Object System.Management.Automation.PSCredential -ArgumentList 'domain\user', (ConvertTo-SecureString -String "password" -AsPlainText -Force)
Invoke-Command -ComputerName LBRGUA97PDK03 -Credential $localCredential -ScriptBlock { Reset-ComputerMachinePassword -Credential $domainCredential }
