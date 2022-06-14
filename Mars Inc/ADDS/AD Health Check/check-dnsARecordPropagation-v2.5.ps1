
#Version: 2.5
#
#Modified: 02.10.2020 (v2.5):
# Directory Service Event Id: 623 cheking (NTDSA: The version store has reached its maximum size)
# Directory Service Event Id: 1519 cheking (Internal Error: Active Directory Domain Services could not perform an operation because the database has run out of version storage)
# 
#Version: 2.3
#
#Modified: 28.05.2019: 
#Modified: 26.11.2018: 
# added Test-WSMan
# Added restart DNS service in the following conditions:
# (1) Condition #1
# DNS RR Availability idssPropagationTest: Failed
# DNS RR Resolution idssPropagationTest.mars-ad.net: Failed
# (2) Condition #2: log: "DNS Server", event id: 4016 (example)
# Log Name:      DNS Server
# Source:        Microsoft-Windows-DNS-Server-Service
# Date:          11/12/2018 2:06:37 AM
# Event ID:      4016
# Level:         Error
# User:          SYSTEM
# Computer:      isxdc102.mars-ad.net
# Description:
# The DNS server timed out attempting an Active Directory service operation on DC=_kerberos._tcp,DC=Mars-AD.Net,cn=MicrosoftDNS,DC=DomainDnsZones,DC=Mars-AD,DC=Net.  Check Active Directory to see that it is functioning properly. The event data contains the error.
#
#
#Author: anatoly.ivanitchev@effem.com
#

[CmdletBinding()]
Param ( [switch]$rwdcOnly, [switch]$dnsResolutionOnly, [switch]$errorsOnly, [string]$dnsNameToTest )

#$dc = "STUDC101"
$dc = (Get-ADDomainController -Discover).Name
$dnsHostRR = "idssPropagationTest"
#$dnsHostRR = "idssPropagationTest-00"
#$dnsIPv4Address = "127.0.0.5"
$dnsIPv4Address = "2.2.127.127"
#$dnsIPv4Address = "2.2.127.128"
#$dnsIPv4Address = "2.2.127.129"
$dnsZone = "mars-ad.net"
$dnsFQDN = $dnsHostRR+"."+$dnsZone
# AZR-EUS2W5726
$dnsIPv4toLookup = "10.200.128.27"
#$dnsIPv4toLookup = "10.120.9.10"
#$dnsIPv4toLookup = "10.64.22.33"
#$dnsFQDNexternal = "sipint2.034d.dedicated.lync.com"
#$dnsFQDNexternal = "o365.mail.effem.com"
$dnsFQDNexternal = "login.zscloud.net"
$sb = "DC=Mars-AD.Net,CN=MicrosoftDNS,DC=DomainDnsZones,DC=Mars-AD,DC=Net"

#$rwdcOnly = $false
#$dnsResolutionOnly = $true

if ($rwdcOnly.IsPresent) { $flt = 'isReadOnly -eq $false' } else { $flt = '*' }
#if ($dnsResolutionOnly.IsPresent) { $dnsFQDN = "sapaep.na.mars" }
#if ($dnsResolutionOnly.IsPresent) { $dnsFQDN = "eguide.mars" }
#if ($dnsResolutionOnly.IsPresent) { $dnsFQDN = "testldaplb.mars-ad.net" }
if ($dnsResolutionOnly.IsPresent) { $dnsFQDN = "saml.federation.effem.com" }
#if ($dnsResolutionOnly.IsPresent) { $dnsFQDN = "qasaml.federation.effem.com" }
#if ($dnsResolutionOnly.IsPresent) { $dnsFQDN = "mtodc103.mars" }
#if ($dnsResolutionOnly.IsPresent) { $dnsFQDN = "bt.com" }
#if ($dnsResolutionOnly.IsPresent) { $dnsFQDN = "eqxvar01.dc.mars" }

if ([boolean]$dnsNameToTest) { $dnsFQDN = $dnsNameToTest }

# minutes
##$waitTime = 5
$waitTime = 15
# seconds
$splitTime = 5

$tryTimes = 3

$verboseOutput = !($errorsOnly.isPresent)
$errorActionPreference = "SilentlyContinue"
$isRestartDNS = $false

# LogName - The EventLogs to search
[String[]]$LogName = "DNS server"
#[String[]]$Events = ("4016","4010")

#[Int32]$DaysAgo = 0

# Starttime - Defaults to the same day, can provide a DateTime object.
#[DateTime]$StartTime = ([DateTime]::Today).AddDays(-$DaysAgo)
[DateTime]$StartTime = ([DateTime]::Today)



function WriteLine ([string]$message, [switch]$noNewLine, [switch]$colorAlert, [switch]$colorOk) {

if ($colorAlert) { $color = "Red" } else {if ($colorOk) { $color = "Green" } else { $color = "Yellow" }}

    if ($verboseOutput) {
        if ($noNewLine) { Write-Host $message -NoNewline -ForegroundColor $color } 
        else { if ($color -eq "Yellow") { Write-Host $message } else { Write-Host $message -ForegroundColor $color }}
    } else { Write-Host "." -NoNewline -ForegroundColor $color }
 }  

<#
# to replace on Test-Connection
function Check-ServerOnline ($computer) {
    $pingStat = $null
    $pingStat = Get-WmiObject win32_pingstatus -f "address='$computer'"
    $hRow = "" | Select Source, Destination, IPv4Address, Time_ms, Result
  
    $hRow.Source = $pingStat.PSComputerName
    $hRow.Destination = $pingStat.Address
    $hRow.IPv4Address = $pingStat.IPv4Address
    $hRow.Time_ms = $pingStat.ResponseTime 
    $hRow.Result = $pingStat.StatusCode 
    
    if ($pingStat.StatusCode -eq $null) {$hRow.Result = -1}
    #if ($pingStat.StatusCode -eq 0) {$hRow.Result = "Ok"} #else {$hRow.Result = "Error"}
    $hRow
    #if($result.statuscode -eq 0) {$true} else {$false}
 }
#>

#$aDNSs = Get-ADDomainController -Filter $flt -Server $dc | sort isReadOnly, OperatingSystem, site, name
$aDNSs = Get-ADDomainController -Filter $flt -Server $dc | sort isReadOnly, site, name
#$aDNSs | sort isReadOnly, OperatingSystem, site, name | ft name, site, isReadOnly, IPv4Address, OperatingSystem -AutoSize
"--------------------------------"
"Total servers: " + $aDNSs.Count
"--------------------------------"

if (!$dnsResolutionOnly.IsPresent) {
    Add-DnsServerResourceRecord -A -Name $dnsHostRR -ZoneName $dnsZone -ComputerName $dc -IPv4Address $dnsIPv4Address -AgeRecord -CreatePtr

    WriteLine "$($dnsFQDN): $($dnsIPv4Address) " -colorOk -noNewLine; WriteLine "HOST(A) RR created"

    "Waiting for $($waitTime) min for RR propagation..."

#split by minutes
    for ($iwt = 1; $iwt -le $waitTime; $iwt++) { 

#split by sleep time
        for ($ist = 1; $ist -le (60/$splitTime); $ist++) { 
            WriteLine "." -colorOk -noNewLine
            sleep -Seconds $splitTime        
        }
        WriteLine ""
    }
}

$ii = 0
$aServersOnline=@()
foreach ($srv in $aDNSs) {
    if ($verboseOutput) {$ii++
        Write-Progress -Activity "Collecting info.." -Status "$($srv.name) ($ii of $($aDNSs.Count)).."  -PercentComplete (($ii / $aDNSs.Count) * 100)
        if ($srv.IsReadOnly) {$sRODC = "RODC" } else {$sRODC = ""}
        WriteLine "Processing: $($srv.name) $($srv.site) $($sRODC) $($srv.IPv4Address) " -noNewLine 
    }
#    $pingRes = Check-ServerOnline($srv.IPv4Address)
    $pingRes = Test-Connection -ComputerName $srv.name -Count 1 -ErrorAction SilentlyContinue	
    #$pingRes
    if ($pingRes -eq $null -or $pingRes.StatusCode -ne 0) { 
            sleep -Seconds $tryTimes
            WriteLine " (1) Offline;" -colorAlert -noNewLine
            #$pingRes = Check-ServerOnline($srv.IPv4Address)
	    $pingRes = Test-Connection -ComputerName $srv.IPv4Address -Count 1 -ErrorAction SilentlyContinue
    }
    if ($pingRes -eq $null -or $pingRes.StatusCode -ne 0) { 
            sleep -Seconds $tryTimes
            WriteLine " (2) Offline;" -colorAlert -noNewLine
            #$pingRes = Check-ServerOnline($srv.IPv4Address)
	    $pingRes = Test-Connection -ComputerName $srv.IPv4Address -Count 1 -ErrorAction SilentlyContinue
    }
    if ($pingRes -ne $null -and $pingRes.StatusCode -eq 0) { 
        $aServersOnline+=$srv; WriteLine " - Online; $($pingRes.ResponseTime) ms" -colorOk


        if (!$dnsResolutionOnly.IsPresent) {
            if ($verboseOutput) { Write-Host "WS-Management (WSMan) Remoting: " -NoNewline}
            $owr=Test-WSMan -ComputerName $srv.name -ErrorAction SilentlyContinue
            if ([boolean]$owr) { WriteLine " Ok" -colorOk } else { WriteLine " Error" -colorAlert }
            $opt = Test-NetConnection -ComputerName $srv.IPv4Address -Port 5985
            if ($opt.TcpTestSucceeded) { WriteLine "wsman - Ok" -colorOk} 
        

            if ($verboseOutput) { Write-Host "TCP ports Availability: "}

            $opt = Test-NetConnection -ComputerName $srv.name -Port 53
            if ($opt.TcpTestSucceeded) { WriteLine "Name resolution - Ok" -colorOk} 
            $optDns = Test-NetConnection -ComputerName $srv.IPv4Address -Port 53
            if ($optDns.TcpTestSucceeded) { WriteLine "dns - Ok" -colorOk
            } else {        
                if (isRestartDNS) {
  	  	    if ($verboseOutput) { Write-Host ">> restarting DNS service..." -ForegroundColor Yellow } 
                    Get-Service dns -ComputerName $srv.name | Restart-Service 
                    $optDns = Test-NetConnection -ComputerName $srv.IPv4Address -Port 53
                    if ($optDns.TcpTestSucceeded) { WriteLine "dns - Ok" -colorOk}         
		}
            }

            $optLdap = Test-NetConnection -ComputerName $srv.IPv4Address -Port 389
            if ($optLdap.TcpTestSucceeded) { WriteLine "ldap - Ok" -colorOk} 
            $opt = Test-NetConnection -ComputerName $srv.IPv4Address -Port 636
            if ($opt.TcpTestSucceeded) { WriteLine "ldaps - Ok" -colorOk} 
            $opt = Test-NetConnection -ComputerName $srv.IPv4Address -Port 445
            if ($opt.TcpTestSucceeded) { WriteLine "microsoft-ds - Ok" -colorOk} 
            $opt = Test-NetConnection -ComputerName $srv.IPv4Address -Port 88
            if ($opt.TcpTestSucceeded) { WriteLine "kerberos - Ok" -colorOk} 
            $opt = Test-NetConnection -ComputerName $srv.IPv4Address -Port 3389
            if ($opt.TcpTestSucceeded) { WriteLine "ms-wbt-server - Ok" -colorOk} 

            if (!$optLdap.TcpTestSucceeded -or !$optDns.TcpTestSucceeded) { continue }  


            if ($verboseOutput) { Write-Host "AD object Replication: " -NoNewline }
            for ($i = 1; $i -le $tryTimes; $i++) {           
                $oRR=Get-ADObject -Filter 'name -eq $dnsHostRR' -SearchBase $sb -Server $srv.Name
                if ([boolean]$oRR) { WriteLine "$($oRR.Name) - Ok" -colorOk; break } else { WriteLine "Failed" -colorAlert; sleep -Seconds $tryTimes }
            }

            if ($verboseOutput) { Write-Host "NTDSA version storage: " -NoNewline }
            [String[]]$Events = ("623")
	    [String[]]$LogName = "Directory Service"   
	    $FilterSearch = @{
                ID        = $Events
                LogName   = $LogName
                StartTime = $StartTime
            }
            try {  $oevt1 = Get-WinEvent -ComputerName $srv.Name -MaxEvents 1 -FilterHashtable $FilterSearch -ErrorAction Stop
                WriteLine "Error 623 " -colorAlert
                Write-Host "$($oevt1.timeCreated): $($oevt1.Message.Substring(0, 127))..." -ForegroundColor Yellow
            } catch { WriteLine "Ok" -colorOk }

            if ($verboseOutput) { Write-Host "NTDSA version storage: " -NoNewline }
            [String[]]$Events = ("1519")
	    [String[]]$LogName = "Directory Service"   
	    $FilterSearch = @{
                ID        = $Events
                LogName   = $LogName
                StartTime = $StartTime
            }
            try {  $oevt1 = Get-WinEvent -ComputerName $srv.Name -MaxEvents 1 -FilterHashtable $FilterSearch -ErrorAction Stop
                WriteLine "Error 1519 " -colorAlert
                Write-Host "$($oevt1.timeCreated): $($oevt1.Message.Substring(0, 127))..." -ForegroundColor Yellow
            } catch { WriteLine "Ok" -colorOk }

            if ($verboseOutput) { Write-Host "DNS - AD Integration: " -NoNewline }
            [String[]]$Events = ("4016")
	    [String[]]$LogName = "DNS server"
	    $FilterSearch = @{
                ID        = $Events
                LogName   = $LogName
                StartTime = $StartTime
            }
            try {  $oevt1 = Get-WinEvent -ComputerName $srv.Name -MaxEvents 1 -FilterHashtable $FilterSearch -ErrorAction Stop
                WriteLine "Error 4016" -colorAlert
                Write-Host "$($oevt1.timeCreated): $($oevt1.Message.Substring(0, 127))..." -ForegroundColor Yellow
            } catch { WriteLine "Ok" -colorOk }


            $bDnsPropTest = $true
            if ($verboseOutput) { Write-Host "DNS RR Availability $($dnsHostRR): " -NoNewline }
            for ($i = 1; $i -le $tryTimes; $i++) {           
                try {
                    $oRR=Get-DnsServerResourceRecord -Name $dnsHostRR -ZoneName $dnsZone -RRType A -ComputerName $srv.Name -ErrorAction SilentlyContinue
                } catch { $oRR = $null }
                if ([boolean]$oRR) { WriteLine "$($oRR.RecordData.IPv4Address.ToString()) - Ok" -colorOk; break } else { WriteLine "Failed" -colorAlert; sleep -Seconds $tryTimes; $bDnsPropTest = $false }
            }
            #if (!$bDnsPropTest) { Get-Service dns -ComputerName $srv.name | Restart-Service }
        }

        if ($verboseOutput) { Write-Host "DNS RR Resolution $($dnsFQDN): " -NoNewline } 
        $bDnsPropTest_FQDN = $true
        for ($i = 1; $i -le $tryTimes; $i++) {           
            $oRR = Resolve-DnsName -Name $dnsFQDN -Type A -Server $srv.Name -DnsOnly      
            if ([boolean]$oRR) { WriteLine "$($oRR.IPAddress) - Ok" -colorOk; $dnsIPv4toLookup = $oRR.IPAddress; break } else { WriteLine "Failed" -colorAlert; sleep -Seconds $tryTimes; $bDnsPropTest_FQDN = $false }
        }
#        if (!$dnsResolutionOnly.IsPresent -and !$bDnsPropTest_FQDN) { 
        if (!$bDnsPropTest_FQDN) { 
            #[DateTime]$StartTime = ([DateTime]::Today).AddDays(-2)
            [String[]]$Events = ("4010")
	    [String[]]$LogName = "DNS server"
            $FilterSearch = @{
                ID        = $Events
                LogName   = $LogName
                StartTime = $StartTime
            }
            try {  
                $oevt2 = Get-WinEvent -ComputerName $srv.Name -MaxEvents 1 -FilterHashtable $FilterSearch -ErrorAction Stop 
                WriteLine "Error 4010" -colorAlert
                Write-Host "$($oevt2.timeCreated): $($oevt.Message.Substring(0, 127))..." -ForegroundColor Yellow
            } catch { WriteLine "Ok" -colorOk }
            
            if (!$dnsResolutionOnly.IsPresent) { 
                if ([boolean]$oevt2) { 
                    if ($verboseOutput) { Write-Host ">> reloading DNS zone..." -ForegroundColor Yellow }  
                        dnscmd $srv.name /zoneReload Mars-AD.Net
                        dnscmd $srv.name /zoneReload effem.com
                } else {
                    if (isRestartDNS) {
			if ($verboseOutput) { Write-Host ">> restarting DNS service..." -ForegroundColor Yellow }             
                        Get-Service dns -ComputerName $srv.name | Restart-Service 
		    }
                }
            }

            if ($verboseOutput) { Write-Host "DNS RR Resolution $($dnsFQDN): " -NoNewline } 
            $bDnsPropTest_FQDN = $true
            for ($i = 1; $i -le $tryTimes; $i++) {           
                $oRR = Resolve-DnsName -Name $dnsFQDN -Type A -Server $srv.Name -DnsOnly      
                if ([boolean]$oRR) { WriteLine "$($oRR.IPAddress) - Ok" -colorOk; $dnsIPv4toLookup = $oRR.IPAddress; break } else { WriteLine "Failed" -colorAlert; sleep -Seconds $tryTimes; $bDnsPropTest_FQDN = $false }
            }     
        }


        if ($verboseOutput) { Write-Host "DNS Reverse RR Resolution $($dnsIPv4toLookup): " -NoNewline }
        for ($i = 1; $i -le $tryTimes; $i++) {           
            $oRR = Resolve-DnsName -Name $dnsIPv4toLookup -Type PTR -Server $srv.Name -DnsOnly      
            if ([boolean]$oRR) { WriteLine "$($oRR.Name) $($oRR.NameHost) - Ok" -colorOk; break } else { WriteLine "Failed" -colorAlert; sleep -Seconds $tryTimes }
        }
	if (!$dnsResolutionOnly.IsPresent) {
        	if ($verboseOutput) { Write-Host "DNS RR Resolution $($dnsFQDNexternal): " -NoNewline }
	        for ($i = 1; $i -le $tryTimes; $i++) {           
        	    $oRR = Resolve-DnsName -Name $dnsFQDNexternal -Type A -Server $srv.Name -DnsOnly      
	            if ([boolean]$oRR) { WriteLine "$($oRR.IPAddress) - Ok" -colorOk; break } else { WriteLine "Failed" -colorAlert; sleep -Seconds $tryTimes }
        	}
	}
    } else { WriteLine " - Offline" -colorAlert}
}

"--------------------------------"
"Online servers: " + $aServersOnline.Count
"--------------------------------"


if (!$dnsResolutionOnly.IsPresent) {
    Remove-DnsServerResourceRecord -RRType A -Name $dnsHostRR -ZoneName $dnsZone -ComputerName $dc -RecordData $dnsIPv4Address -Force

    WriteLine "$($dnsFQDN): $($dnsIPv4Address) " -colorOk -noNewLine; Write-Host "HOST(A) RR removed"
}
"Done!"
