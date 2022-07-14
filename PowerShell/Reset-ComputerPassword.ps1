Function Reset-ADComputerMachinePassword {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $computers = Import-Csv -Path "C:\Users\abelraf\OneDrive - Mars Inc\Documents\Identity Team\Projects\ADDS\PingCastle reports\computerpasswordlastset Mars-AD by LastLogonTimeStamp.csv"
    $localCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ".\localuser", (ConvertTo-SecureString -String "password" -AsPlainText -Force) #Get-Credential
    $domainCredential = New-Object System.Management.Automation.PSCredential -ArgumentList 'DOMAIN\domainuser', (ConvertTo-SecureString -String "password" -AsPlainText -Force) #Get-Credential

    Foreach ($computer in $computers) {
        Invoke-Command -ComputerName $computer.Name -Credential $using:localCredential -ScriptBlock { Reset-ComputerMachinePassword -Credential $using:domainCredential }
    }
}
