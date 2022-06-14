<#
.Synopsis
   Function to uninstall DC agents
.DESCRIPTION
   According to domain controller type (RO or RW), you call out the appropriate function to uninstall the required agents
.EXAMPLE
   Once is executed, you choose [1] for uninstalling RO agents or [2] for uninstalling RW agents
.AUTHOR
   Anatoly Ivanitchev - anatoly.ivanitchev@effem.com 
   Rafael Abel - rafael.abel@effem.com
.DATE
    09/09/2021
#>


function Install-RODCagent {

    $splunkforwarder = splunkforwarder-7.2.0-tran.msi
    $rapid = Rapid7\agentInstaller-x86_64.msi
    &$NPCAP = npcap-1.00-oem.exe
    &$AzureATP = "Azure ATP Sensor Setup.exe"

    Write-host "Upgrade Splunk UF agent to 7.2.0"
    start-process "msiexec.exe" -arg "/i $splunkforwarder /quiet /qn /norestart /l*!+v install_uf.log" -wait

    Write-host "Install Rapid 7 "
    start-process "msiexec.exe" -arg "/i $rapid /quiet /qn /norestart /l*!+v install_r7.log" -wait

    Write-host "Install NPCAP"
    .\$NPCAP /S /loopback_support=no /winpcap_mode=yes

    Write-Host "Install Azure ATP Sensor"
    .\"Azure ATP Sensor Setup\$AzureATP" /quiet NetFrameworkCommandLineArguments="/q" AccessKey="QGetL+CGJGF4AKCfSRMBaA2JHRT0oCXm17C2AOSqIcHtbTooeDMTaO9kkp2lPDrIm8JZQEYLBpKZaG8iVDFCPA=="
    
    Write-Host "Ready."
}

function Install-RWDCagent {

    $azureADPasswordProtection = AzureADPasswordProtectionDCAgentSetup.msi
    $pswcns = "Password Change Notification Service.msi"
    $rmadbkpagent = RMAD\BackupAgent.msi 
    $splunkforwarder = splunkforwarder-7.2.0-tran.msi
    $rapid = Rapid7\agentInstaller-x86_64.msi
    &$NPCAP = npcap-1.00-oem.exe
    &$AzureATP = "Azure ATP Sensor Setup.exe"
  
    Write-Host "AzureADPasswordProtection"
    start-process "msiexec.exe" -arg "/i $azureADPasswordProtection /quiet /qn /norestart" -wait

    Write-Host "Password Change Notification Service"
    start-process "msiexec.exe" -arg "/i ""Password Change Notification Service x64\$pswcns"" /quiet /qn /norestart" -wait

    Write-Host  "RMAD Backup Agent"
    start-process "msiexec.exe" -arg "/i $rmadbkpagent /quiet /qn /norestart /l*!+v install_ba.log" -wait

    "RMAD Recovery Agent"
    .\RMAD\RecoveryAgent64.exe /qn MANAGE_SERVICE=TRUE FRS_FIREWALL_SETTINGS_CONFIGURE=1 /l*!+v install_ra.log

    Write-Host "Upgrade Splunk UF agent to 7.2.0"
    start-process "msiexec.exe" -arg "/i $splunkforwarder /quiet /qn /norestart /l*!+v install_uf.log" -wait

    Write-Host "Install Rapid 7 "
    start-process "msiexec.exe" -arg "/i $rapid /quiet /qn /norestart /l*!+v install_r7.log" -wait

    Write-Host "Install NPCAP"
    .\$NPCAP /S

    Write-Host "Install Azure ATP Sensor"
    Start-Sleep 30
    .\"Azure ATP Sensor Setup\$AzureATP" /quiet NetFrameworkCommandLineArguments="/q" AccessKey="QGetL+CGJGF4AKCfSRMBaA2JHRT0oCXm17C2AOSqIcHtbTooeDMTaO9kkp2lPDrIm8JZQEYLBpKZaG8iVDFCPA=="

    Write-Host "Ready."
}

#Execution
$message = Read-Host "Please select 1 [DEFAULT] for installing RODC agents or 2 for installing RWDC agents"
$rodcagent = Install-RODCagent
$rwdcagent = Install-RWDCagent

switch ($message) {
    1 { $rodcagent }
    2 { $rwdcagent }
    Default { $rwdcagent }
}