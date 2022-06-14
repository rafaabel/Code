<#
.DESCRIPTION
  DC Server promotion
  

.NOTES
  Version:        1.23
  Author:         anatoly.ivanitchev@effem.com, IDSS, Mars Inc.
  Modified:       24.07.2020
  Added MachineAccount test to fix issue with PASSWD_NOTREQD for RWDC
  Modified:       30.06.2020 v1.22
  Added DHCP section
  Modified:       18.06.2020 v1.21
  Fixed minor errors
  Modified:       20.04.2020 v1.2
  Added promoMode json option
  Modified:       28.03.2020 v1.1
  Added DC promo part
  Creation Date:  11.03.2020 v1.0
  History: Based on dns-Promo.ps1
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

[CmdletBinding()]
Param (
    # Start DNS Server promotion  
    [Parameter(Mandatory = $false)]
    [ValidateSet("startPromo", "postChecking", "readConfig")]  
    [string]$goAheadMode = "readConfig",

    [Parameter(Mandatory = $false)]
    #[string]$configFile #= "d:\a\slib\promo\rodc-PromoConfig.json"
    [string]$configFile = "dc-PromoConfig.json"
) 
#---------------------------------------------------------[Initializations]--------------------------------------------------------

$IS_DEBUG = $false

if ($IS_DEBUG) {
    $ErrorActionPreference = 'Stop'
}
else {
    $ErrorActionPreference = 'SilentlyContinue'
}

if (!(Test-Path $configFile)) {
    Write-Host "RODC promo config file coudn't be found: " -ForegroundColor Red -NoNewline; Write-Host $configFile -ForegroundColor Yellow
    Exit 1
}

$goAhead = ($goAheadMode -eq "startPromo")

$objCfg = Get-Content -Raw -Path $configFile | ConvertFrom-Json


#if ($IS_DEBUG) {
#    $niAlias = "Wi-Fi"
#} else {
$niAlias = $objCfg.NetworkInterface.Alias
#}
$niDnsServers = $objCfg.NetworkInterface.DnsServerAddresses
$dnsForwarders = $objCfg.DnsServer.ForwarderAddresses
$dnsDebugLogging = $objCfg.DnsServer.DebugLogging
$dhcpLogsSize = $objCfg.DhcpServer.DhcpLogsSize
$volumeLabel = $objCfg.VolumLabel
$promoRoles = $objCfg.RolesAndFeatures
$dcPromoCfg = $objCfg.DomainController
$dcType = $dcPromoCfg.Type
$oAgents = $objCfg.Agents

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# json section.promoMode definitions
# $goAheadMode = "startPromo" will configure / promo only json sections set with "Fix"
$PROMO_MODE_FIX = "Fix"
# only check the json section / no actual promotion
#$PROMO_MODE_CHECK = "Check"
# a json section configured with "Skip" will be excluded from checking and promotion parts
$PROMO_MODE_SKIP = "Skip"

# DomainController.Type
$DC_READ_ONLY = "RODC"
$DC_READ_WRITE = "RWDC"

# RolesAndFeatures PromotionTypes
$PROMO_TYPE_DHCP = "DHCP"

$starLine = "******************************************************************************"
#$compLocation = "OU=Domain Controllers,DC=Mars-AD,DC=Net"
$compLocation = "OU=Domain Controllers,X"

$RWDC_MACHINE_ACCOUNT = 0x82000
#test: MachineAccount
#Warning:  Attribute userAccountControl
#0x82020 (532512) = ( PASSWD_NOTREQD | SERVER_TRUST_ACCOUNT | TRUSTED_FOR_DELEGATION )
#Typical setting for a DC is 0x82000 (532480) = ( SERVER_TRUST_ACCOUNT | TRUSTED_FOR_DELEGATION )

#RODC
#0x5001000 (83890176) = ( WORKSTATION_TRUST_ACCOUNT | TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION | PARTIAL_SECRETS_ACCOUNT)

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function  Write-aiParamValue {
    Param (
        [Parameter(Mandatory = $False)]
        [string]$startString = "Parameter",

        [Parameter(Mandatory = $False)]
        [string]$endString = "Value",

        [Parameter(Mandatory = $False)]
        [switch]$Yellow = $False    
    )

    Write-Host $startString -ForegroundColor White -NoNewline
    if ($Yellow) { Write-Host $endString -ForegroundColor Yellow } else { Write-Host $endString -ForegroundColor Green }   
}  

function  Write-aiParamValueRG {
    Param (
        [Parameter(Mandatory = $False)]
        [string]$startString = "Parameter",

        [Parameter(Mandatory = $False)]
        [string]$endStringGreen = "greenValue",

        [Parameter(Mandatory = $False)]
        [string]$endStringRed = "redValue",

        [Parameter(Mandatory = $False)]
        [boolean]$isGreen = $true   
    )

    Write-Host $startString -ForegroundColor White -NoNewline
    if ($isGreen) { Write-Host $endStringGreen -ForegroundColor Green } else { Write-Host $endStringRed -ForegroundColor Red }
}  
#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Host "Roles: $($promoRoles.PromotionTypes)"
Write-Host "Start Promotion [$($dcPromoCfg.Type)]: $goAhead"
Write-Host "Mode: $goAheadMode"
Write-Host

#Output the promo details
if (!($goAhead)) {
    Write-Host $starLine
    
    Write-aiParamValue -startString "CR#: " -endString $($objCfg.ConfigurationMetadata.CRNumber)
    Write-aiParamValue -startString "Description: " -endString $($objCfg.ConfigurationMetadata.Description) 
    Write-aiParamValue -startString "Scheduled: " -endString $($objCfg.ConfigurationMetadata.ScheduledDate)

    Write-Host $starLine
    
    $SysInfo = New-Object -ComObject "ADSystemInfo"
    $compDN = $SysInfo.GetType().InvokeMember("ComputerName", "GetProperty", $Null, $SysInfo, $Null)
    $domainDN = $compDN.Substring($compDN.IndexOf("DC="))
    $compLocation = $compLocation.Replace("X", $domainDN)
    Write-aiParamValue -startString "Target computer: " -endString $compDN -Yellow
    Write-aiParamValue -startString "New computer object location: " -endString $compLocation

    if (($goAheadMode -eq "postChecking") -and ($dcType -eq $DC_READ_WRITE) -and $compDN.Contains($compLocation)) {
        $oDC = Get-ADComputer $env:COMPUTERNAME -Properties userAccountControl
        if ($oDC.userAccountControl -ne $RWDC_MACHINE_ACCOUNT) {
            Write-aiParamValue -startString "MachineAccount: " -endString $oDC.userAccountControl -Yellow 
            Write-Host "Trying to fix..." -ForegroundColor Yellow -NoNewline
            Set-ADComputer $env:COMPUTERNAME -PasswordNotRequired $false
            Start-Sleep 15
            Write-Host " Done." -ForegroundColor Green
            $oDCx = Get-ADComputer $env:COMPUTERNAME -Properties userAccountControl
            if ($oDCx.userAccountControl -eq $RWDC_MACHINE_ACCOUNT) {
                Write-aiParamValue -startString "MachineAccount fixed: " -endString $oDCx.userAccountControl
            }
            else {
                Write-Host "Fix failed. Please try again or fix it manually:" -ForegroundColor Red
                Write-Host "see dcdiag /test:MachineAccount" -ForegroundColor Yellow
            }    
        }
    }

    if ($volumeLabel.promoMode -ne $PROMO_MODE_SKIP) {
        Write-Host $starLine
        
        $cvl = (Get-Volume -DriveLetter "C").FileSystemLabel
        if ([string]::IsNullOrEmpty($cvl)) { $cvl = "<Empty>" } 
        Write-aiParamValueRG -startString "Volume Label C: " -endStringGreen "$($volumeLabel.C)" -endStringRed "$cvl" -isGreen ($($volumeLabel.C) -eq $cvl)
        $cvl = (Get-Volume -DriveLetter "D").FileSystemLabel
        if ([string]::IsNullOrEmpty($cvl)) { $cvl = "<Empty>" } 
        Write-aiParamValueRG -startString "Volume Label D: " -endStringGreen "$($volumeLabel.D)" -endStringRed "$cvl" -isGreen ($($volumeLabel.D) -eq $cvl)
        
        if ($dcType -eq $DC_READ_WRITE) {
            $cvl = (Get-Volume -DriveLetter "E").FileSystemLabel
            if ([string]::IsNullOrEmpty($cvl)) { $cvl = "<Empty>" } 
            Write-aiParamValueRG -startString "Volume Label E: " -endStringGreen "$($volumeLabel.E)" -endStringRed "$cvl" -isGreen ($($volumeLabel.E) -eq $cvl)
            $cvl = (Get-Volume -DriveLetter "F").FileSystemLabel
            if ([string]::IsNullOrEmpty($cvl)) { $cvl = "<Empty>" } 
            Write-aiParamValueRG -startString "Volume Label F: " -endStringGreen "$($volumeLabel.F)" -endStringRed "$cvl" -isGreen ($($volumeLabel.F) -eq $cvl)
        }
    }

    Write-Host $starLine

    $sNicName = (Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' })[0].Name
    $isLegalNicName = ($niAlias -like $sNicName)
    Write-aiParamValueRG -startString "Network Interface Alias: " -endStringGreen "$niAlias" -endStringRed "$sNicName" -isGreen $isLegalNicName

    if (!$isLegalNicName) {
        Write-Host; Write-Host "[Error]: " -NoNewline -ForegroundColor Red
        Write-Host "The Network Interface should be renamed to " -NoNewline -ForegroundColor Yellow
        Write-Host $niAlias -NoNewline -ForegroundColor Green
        Write-Host " before you can continue. " -ForegroundColor Yellow
        Write-Host; Write-Host "Ready." -ForegroundColor Green
        Exit 1
    }
   
    $ipv6 = Get-NetAdapterBinding -Name $niAlias -ComponentID ms_tcpip6
    Write-aiParamValueRG -startString "$($ipv6.DisplayName): " -endStringGreen "Disabled" -endStringRed "Enabled" -isGreen (!($ipv6.Enabled))
    $ipDNS = Get-DnsClientServerAddress -AddressFamily IPv4 -InterfaceAlias $niAlias
    Write-aiParamValue -startString "Current DNS Servers: " -endString "$($ipDNS.ServerAddresses)" -Yellow

    if ($objCfg.NetworkInterface.promoMode -ne $PROMO_MODE_SKIP) {    
        Write-aiParamValue -startString "New DNS Servers: " -endString "$niDnsServers"
    }    

    Write-Host $starLine
    
    try {
        $osct = Get-ScheduledTask -TaskName "Daily EPV compliance check" -TaskPath "\" -ErrorAction Stop
        Write-aiParamValueRG -startString '"Daily EPV compliance check" Scheduled Task State: ' -endStringGreen "Disabled" -endStringRed "Enabled" -isGreen ($osct.State -eq "Disabled")
    }
    catch {
        Write-aiParamValue -startString '"Daily EPV compliance check" Scheduled Task: ' -endString "Doesn't exist" -Yellow
    }   

    Write-Host $starLine

    if ($objCfg.DnsServer.promoMode -ne $PROMO_MODE_SKIP) {    
        Write-aiParamValue -startString "New DNS Forwarders: " -endString "$dnsForwarders"
    }

    if ($goAheadMode -eq "postChecking") {
        Write-aiParamValue -startString "Configured DNS Forwarders: " -endString "$((Get-DnsServerForwarder).IPAddress.IPAddressToString)" -Yellow
    }

    if ($promoRoles.promoMode -ne $PROMO_MODE_SKIP) {   
        Write-Host $starLine

        [Array]$swf = $promoRoles.CommonFeatures
        foreach ($pt in $promoRoles.PromotionTypes) { $swf += $promoRoles.$pt }
        Get-WindowsFeature -Name $swf | Format-Table -AutoSize
        #Get-WindowsFeature -Name Windows-Server-Backup,AD-Domain-Services,RSAT-ADDS-Tools,DNS,RSAT-DNS-Server,DHCP,RSAT-DHCP | ft -AutoSize
    }
   
    # Get-SmbServerConfiguration | ft EnableSMB2Protocol, EnableSMB1Protocol -AutoSize 

    if ($oAgents.promoMode -ne $PROMO_MODE_SKIP) {    
        Write-Host $starLine

        $apps = Get-WmiObject -Class Win32_Product
        if ($goAheadMode -eq "postChecking") {         
            #post-Config: Checking agents / services installation       
            for ($i = 1; $i -le $oAgents.Count; $i++) { 
                $oAg = $oAgents."Agent$i"
                if (!($dcType -in $oAg.DCType)) { Continue }
                if ($oAg.Action -eq "Uninstall") {
                    Write-aiParamValueRG -startString "$($oAg.Name): " -endStringGreen "Missing" -endStringRed "Installed" -isGreen (![boolean]($apps | Where-Object { $_.Name -like $($oAg.Filter) }))
                }
                else {
                    Write-aiParamValueRG -startString "$($oAg.Name): " -endStringGreen "Installed" -endStringRed "Missing" -isGreen ([boolean]($apps | Where-Object { $_.Name -like $($oAg.Filter) }))
                }
            }   
        }
        else { $apps | Format-Table Name -AutoSize }
    }

    #Execute promotion steps    
}
else {

    # Configure Volume Labels
    if ($volumeLabel.promoMode -eq $PROMO_MODE_FIX) {
        Write-Host "Changing volume labels..." -ForegroundColor Yellow -NoNewline
        Set-Volume -DriveLetter "C" -NewFileSystemLabel $volumeLabel.C
        Set-Volume -DriveLetter "D" -NewFileSystemLabel $volumeLabel.D
        if ($dcType -eq $DC_READ_WRITE) {
            Set-Volume -DriveLetter "E" -NewFileSystemLabel $volumeLabel.E
            Set-Volume -DriveLetter "F" -NewFileSystemLabel $volumeLabel.F        
        }
        Write-Host " Done." -ForegroundColor Green
    }

    #Uninstall extra agents  
    if ($oAgents.promoMode -eq $PROMO_MODE_FIX) {    
        for ($i = 1; $i -le $oAgents.Count; $i++) { 
            $oAg = $oAgents."Agent$i"
            if ($oAg.Action -eq "Uninstall" -and $dcType -in $oAg.DCType) { 
                Write-Host "Uninstalling $($oAg.Name). Please wait..." -ForegroundColor Yellow -NoNewline
                #Write-Host "Note. It can get stuck sometimes. Just press <Enter> from time to time." -ForegroundColor Yellow
                (Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like $oAg.Filter }).Uninstall() | Out-Null
                Write-Host " Done." -ForegroundColor Green
            }        
        }
    } 

    #post-Config: disable Daily EPV compliance check Scheduled Task
    Write-Host "Disabling 'Daily EPV compliance check' scheduled task..." -ForegroundColor Yellow -NoNewline
    #Get-ScheduledTask -TaskName "Daily EPV compliance check" -TaskPath "\" | Disable-ScheduledTask | Out-Null
    #Weekly MGS Reboot Policy
    try {
        $osct = Get-ScheduledTask -TaskName "Daily EPV compliance check" -TaskPath "\" -ErrorAction Stop
        $osct | Disable-ScheduledTask | Out-Null
        Write-Host " Done." -ForegroundColor Green
    }
    catch {
        Write-Host " Doesn't exist." -ForegroundColor Green
    }   

    Write-Host "Removing Support\Puppet folders..." -ForegroundColor Yellow -NoNewline
    Remove-Item -Path "C:\Support\Puppet\" -Force -Recurse   
    Remove-Item -Path "C:\ProgramData\PuppetsLab\" -Force -Recurse
    Remove-Item -Path "C:\Support\Utils\EPV-Admin-Config.ps1" -Force
    Write-Host " Done." -ForegroundColor Green
    

    #set DNS servers order list for NIC IPv4 
    Write-Host "Configure Network Interface..." -ForegroundColor Yellow -NoNewline
    Disable-NetAdapterBinding -Name $niAlias -ComponentID ms_tcpip6
    if ($objCfg.NetworkInterface.promoMode -eq $PROMO_MODE_FIX) {    
        #Set-DnsClientServerAddress -InterfaceAlias $niAlias -ServerAddresses 10.26.122.71, 10.24.1.202, 10.121.15.222, 127.0.0.1 -WhatIf
        Set-DnsClientServerAddress -InterfaceAlias $niAlias -ServerAddresses $niDnsServers #-WhatIf
    }    
    Write-Host " Done." -ForegroundColor Green

    #install Windows Server Backup feature & DNS Server role
    if ($promoRoles.promoMode -eq $PROMO_MODE_FIX) {    
        Write-Host "Installing Roles and Features..." -ForegroundColor Yellow
        [Array]$swf = $promoRoles.CommonFeatures
        foreach ($pt in $promoRoles.PromotionTypes) { $swf += $promoRoles.$pt }
        Get-WindowsFeature -Name $swf | Where-Object { !($_.Installed) } | Install-WindowsFeature #-Name $swf 
        #Install-WindowsFeature -Name Windows-Server-Backup,AD-Domain-Services,RSAT-ADDS-Tools,DNS,RSAT-DNS-Server,DHCP,RSAT-DHCP
        #Write-Host " Done." -ForegroundColor Green
    }
    Write-Host

    #Set-SmbServerConfiguration -EnableSMB2Protocol $true
    #Set-SmbServerConfiguration -EnableSMB1Protocol $false

    #post-Config: configure DNS Debug Logging
    if ($objCfg.DnsServer.promoMode -eq $PROMO_MODE_FIX) {    
        Write-Host "Configuring DNS Logging..." -ForegroundColor Yellow #-NoNewline
        #./dns-postConfig.cmd  
        #DNS only: DNS Debug Logging 
        #if ($dcType -eq $DC_READ_ONLY) { $dnsLogPath = "c:\dns" } else { $dnsLogPath = "e:\dns" }
        $dnsLogPath = $dnsDebugLogging.$dcType.logfilePath
        mkdir $dnsLogPath | Out-Null
        icacls $dnsLogPath /c /inheritance:r /grant "NT AUTHORITY\SYSTEM:(OI)(CI)(F)" /grant "BUILTIN\Administrators:(OI)(CI)(F)"
        #        dnscmd /config /logfilePath "$(Join-Path -Path $dnsLogPath -ChildPath 'dns.log')"
        dnscmd /config /logfilePath "$(Join-Path -Path $dnsLogPath -ChildPath $dnsDebugLogging.$dcType.logfileName)"
        #        dnscmd /config /logLevel 0xf321
        dnscmd /config /logLevel $dnsDebugLogging.$dcType.logLevel
        #        dnscmd /config /logfileMaxSize 0xc800000
        dnscmd /config /logfileMaxSize $dnsDebugLogging.$dcType.logfileMaxSize
        #Write-Host " Done." -ForegroundColor Green
    }    

    if ($objCfg.DhcpServer.promoMode -eq $PROMO_MODE_FIX) {    
        #post-Config: DHCP only: DHCP Server event logs 
        if ($PROMO_TYPE_DHCP -in $promoRoles.PromotionTypes) {
            Write-Host "Configuring DHCP Event Logs size..." -ForegroundColor Yellow -NoNewline
            wevtutil sl DhcpAdminEvents /ms:$($dhcpLogsSize.DhcpAdminEvents)    
            wevtutil sl Microsoft-Windows-Dhcp-Server/FilterNotifications /ms:$($dhcpLogsSize.DhcpServerFilterNotifications)
            wevtutil sl Microsoft-Windows-Dhcp-Server/Operational /ms:$($dhcpLogsSize.DhcpServerOperational)  
            Set-DhcpServerv4DnsSetting -UpdateDnsRRForOlderClients $False -DeleteDnsRROnLeaseExpiry $True -DisableDnsPtrRRUpdate $False -DynamicUpdates OnClientRequest
            Set-DhcpServerSetting -ConflictDetectionAttempts 2
            Write-Host " Done." -ForegroundColor Green
            
            Write-Host "Currrent DHCP Server for " -ForegroundColor White -NoNewline
            Write-Host "$($dcPromoCfg.adSite) " -ForegroundColor Green -NoNewline; Write-Host "site:" -ForegroundColor White
            Get-DhcpServerInDC | findstr /i $dcPromoCfg.adSite
        }
    }    

    #post-Config: configure DNS Forwarders
    if ($objCfg.DnsServer.promoMode -eq $PROMO_MODE_FIX) {    
        Write-Host "Reset DNS Forwarders..." -ForegroundColor Yellow -NoNewline
        #Set-DnsServerForwarder -IPAddress 8.8.8.8, 8.8.4.4 -WhatIf   
        Set-DnsServerForwarder -IPAddress $dnsForwarders #-WhatIf
        Write-Host " Done." -ForegroundColor Green
    }

    if ($dcPromoCfg.promoMode -eq $PROMO_MODE_FIX) {    
        #$pwd = ConvertTo-SecureString -String 'password' -AsPlainText -Force
        Write-Host; Write-Host "We are ready to start promotion of a new Domain Controller" -ForegroundColor Green

        $adSite = $dcPromoCfg.adSite
        $dnsRoot = (Get-ADDomain).dnsRoot
        $ntdsPath = $dcPromoCfg.$dcType.ntdsPath
        $logPath = $dcPromoCfg.$dcType.logPath
        $sysvolPath = $dcPromoCfg.$dcType.sysvolPath

        Write-aiParamValue -startString "dnsRoot: " -endString $dnsRoot
        Write-aiParamValue -startString "AD Site: " -endString $adSite
        Write-aiParamValue -startString "NTDS DB path: " -endString $ntdsPath
        Write-aiParamValue -startString "NTDS log path: " -endString $logPath
        Write-aiParamValue -startString "NTDS sysvol path: " -endString $sysvolPath
        Write-aiParamValue -startString "IFM source: " -endString $dcPromoCfg.ifmSource
        if ($dcPromoCfg.ifmSource) {
            Write-aiParamValue -startString "IFM source path: " -endString $dcPromoCfg.$dcType.ifmPath 
        }           

        Write-Host; Write-Host "The server will restart upon the completion of the install operation" -ForegroundColor Green
        Write-Host; Write-Host "Enjoy the process..." -ForegroundColor Green; Write-Host
        Start-Sleep -Seconds 5
        $pwd = Read-Host -Prompt "Enter Safe Mode Administrator Password" -AsSecureString


        Import-Module ADDSDeployment

        if ($dcPromoCfg.ifmSource) {
            $ifmPath = $dcPromoCfg.$dcType.ifmPath 
            Write-Host "Using IFM from: $ifmPath"; Write-Host
            Install-ADDSDomainController -DatabasePath $ntdsPath -DomainName $dnsRoot -InstallationMediaPath $ifmPath -InstallDns -LogPath $logPath -ReadOnlyReplica:($dcType -eq $DC_READ_ONLY) -SafeModeAdministratorPassword $pwd -SiteName $adSite -SysvolPath $sysvolPath -Force -Confirm
        }
        else {
            Write-Host "Without using IFM"; Write-Host
            Install-ADDSDomainController -DatabasePath $ntdsPath -DomainName $dnsRoot -InstallDns -LogPath $logPath -ReadOnlyReplica:($dcType -eq $DC_READ_ONLY) -SafeModeAdministratorPassword $pwd -SiteName $adSite -SysvolPath $sysvolPath -Force -Confirm
        }
    }    
}

Write-Host; Write-Host "Ready." -ForegroundColor Green