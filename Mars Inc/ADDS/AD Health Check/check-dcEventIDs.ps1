# 
# Check Event ID for domain controllers

#
#Modified: 10.06.2021 (v1.05):
#
# Added Pysical Memory Usage info & top 3 processes
#
#
#Modified: 08.06.2021 (v1.04):
#
# Added System / Microsoft-Windows-Resource-Exhaustion-Detector / EventId: 2004
# Example of Description:
# Windows successfully diagnosed a low virtual memory condition. 
# The following programs consumed the most virtual memory: splunk-MonitorNoHandle.exe (142180) consumed 40881606656 bytes, 
# dns.exe (7364) consumed 2007265280 bytes, and lsass.exe (1116) consumed 1574715392 bytes.
#
#Modified: 20.05.2020 (v1.03):
#
# Added lingering objects detection
# Directory Service Event ID: 1388, 1988, 2042
# https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc949134(v=ws.10)
# https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc949136(v=ws.10)
#
# https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc949124(v=ws.10)
# https://docs.microsoft.com/en-us/archive/blogs/askds/remove-lingering-objects-that-cause-ad-replication-error-8606-and-friends
# https://docs.microsoft.com/en-us/archive/blogs/askds/introducing-lingering-object-liquidator-v2
# https://techcommunity.microsoft.com/t5/ask-the-directory-services-team/introducing-lingering-object-liquidator-v2/ba-p/400475
#
#Modified: 10.03.2020 (v1.02):
#
# Added last reboot time
#
#Modified: 19.02.2020 (v1.02):
#
# DNS Server Event ID: 4016, 4010
#
#Modified: 17.02.2020 (v1.01):
#
# Event ID: 602 
# https://support.microsoft.com/en-in/help/3079385/background-clean-up-skipped-pages-ntds-isam-event-602-in-ad-ds-or-lds
#
# Event ID: 623 
# https://support.microsoft.com/en-sg/help/974803/the-domain-controller-runs-slower-or-stops-responding-when-the-garbage
# https://support.microsoft.com/en-us/help/248047/phantoms-tombstones-and-the-infrastructure-master
# https://docs.microsoft.com/en-us/archive/blogs/askds/the-version-store-called-and-theyre-all-out-of-buckets
#
# Event ID: 2866
# https://support.oneidentity.com/active-roles/kb/254422/dynamic-group-error-a-required-audit-event-could-not-be-generated-for-the-operation
#
#Modified: 02.02.2020 (v1.0):
#
#Author: anatoly.ivanitchev@effem.com
#

[CmdletBinding()]
Param ( [switch]$AllDCs, [Int32]$DaysAgo = 3, [switch]$errorsOnly )

#$dc = "STUDC101"
$dc = (Get-ADDomainController -Discover).Name

#$rwdcOnly = $false

if ($AllDCs.IsPresent) { $flt = '*' } else { $flt = 'isReadOnly -eq $false' }
$verboseOutput = !($errorsOnly.isPresent)
$errorActionPreference = "SilentlyContinue"

# LogName - The EventLogs to search
#[String[]]$LogName = "DNS server"
#[String[]]$Events = ("4016","4010")
##[String[]]$Events = ("5777")
##[String[]]$LogName = "System"
##[String[]]$Descriptions = ("NETLOGON:")
##[String[]]$Events = ("2866", "623", "602", "1519", "2095","4016","4010","12294")
[String[]]$Events = ("2866", "623", "602", "1519", "2095","4016","4010","1388","1988","2042","2004")
##[String[]]$LogNames = ("Directory Service", "Directory Service", "Directory Service", "Directory Service", "Directory Service", "DNS Server", "DNS Server","System")
[String[]]$LogNames = ("Directory Service", "Directory Service", "Directory Service", "Directory Service", "Directory Service", "DNS Server", "DNS Server", "Directory Service", "Directory Service", "Directory Service", "System")
[String[]]$Descriptions = ("Maximum Audit Queue Size reached:", "NTDSA version storage issue:", "NTDSA: Background clean-up skipped pages:",`
			 "Version Storage limit reached:", "USN rollback detection:", "DNS - AD Integration:", "DNS Zone stuck:",`
			 "Lingering Objects 1388:", "Lingering Objects 1988:", "Lingering Objects 2042:", "Resource exhauston detection:")
##			 "Version Storage limit reached:", "USN rollback detection:", "DNS - AD Integration:", "DNS Zone stuck:","KB887433:")
#12294
#https://www.reddit.com/r/sysadmin/comments/2zmdui/idea_change_password_when_account_lockouts_fail/


#[Int32]$DaysAgo = 7
#[Int32]$DaysAgo = 3

# Starttime - Defaults to the same day, can provide a DateTime object.
[DateTime]$StartTime = ([DateTime]::Today).AddDays(-$DaysAgo)
#[DateTime]$StartTime = ([DateTime]::Today)


function WriteLine ([string]$message, [switch]$noNewLine, [switch]$colorAlert, [switch]$colorOk) {

if ($colorAlert) { $color = "Red" } else {if ($colorOk) { $color = "Green" } else { $color = "Yellow" }}

    if ($verboseOutput) {
        if ($noNewLine) { Write-Host $message -NoNewline -ForegroundColor $color } 
        else { if ($color -eq "Yellow") { Write-Host $message } else { Write-Host $message -ForegroundColor $color }}
    } else { Write-Host "." -NoNewline -ForegroundColor $color }
 }  


"--------------------------------"
Write-Host "Domain Controllers: " -NoNewline; Write-Host "$(if ($flt.Length -eq 1) {'All'} else {'RWDC'})" -ForegroundColor Yellow 
Write-Host "Search Events for: " -NoNewline; Write-Host "$($DaysAgo) days" -ForegroundColor Yellow 
"================================"


###$flt = 'name -like "isxdc10*"'
####$flt = 'name -like "azr-eus2w6707"'

#$aDNSs = Get-ADDomainController -Filter $flt -Server $dc | sort isReadOnly, OperatingSystem, site, name
$aDNSs = Get-ADDomainController -Filter $flt -Server $dc | sort isReadOnly, site, name
#$aDNSs | sort isReadOnly, OperatingSystem, site, name | ft name, site, isReadOnly, IPv4Address, OperatingSystem -AutoSize
"Total servers: " + $aDNSs.Count
"--------------------------------"

$ii = 0
$aServersOnline=@()
foreach ($srv in $aDNSs) {

Write-Host

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

	    $sess = New-PSSession -ComputerName $srv
	    $slbt = Invoke-Command -Session $sess -ScriptBlock { (Get-CimInstance -ClassName win32_operatingsystem).LastBootUpTime.dateTime }
	    $stz = Invoke-Command -Session $sess -ScriptBlock { ([System.TimeZoneInfo]::Local).displayName }
	    WriteLine "LastBootUpTime: $($slbt) $($stz)"

            if ($verboseOutput) { Write-Host "WS-Management (WSMan) Remoting tcp: 5985: " -NoNewline}
            $owr=Test-WSMan -ComputerName $srv.name -ErrorAction SilentlyContinue
            if ([boolean]$owr) { WriteLine " Ok" -colorOk } else { WriteLine " Error" -colorAlert }
            $opt = Test-NetConnection -ComputerName $srv.IPv4Address -Port 5985
            if ($opt.TcpTestSucceeded) { WriteLine "wsman - Ok" -colorOk} 
        

            for ($i = 0; $i -lt $Events.Count; $i++) { 
                [String[]]$Event = $Events[$i]
	            [String[]]$LogName = $LogNames[$i]
                [String[]]$Description = $Descriptions[$i]
                if ($verboseOutput) { Write-Host "$($Description) " -NoNewline }

    	        $FilterSearch = @{
                    ID        = $Event
                    LogName   = $LogName
                    StartTime = $StartTime
                }
                try {  $oevt1 = Get-WinEvent -ComputerName $srv.Name -MaxEvents 1 -FilterHashtable $FilterSearch -ErrorAction Stop
#                try {  $oevt1 = Invoke-Command -Session $sess -ScriptBlock { param ($fs) Get-WinEvent -MaxEvents 1 -FilterHashtable $fs -ErrorAction Stop } -ArgumentList $FilterSearch
                    WriteLine "Error $($oevt1.Id)" -colorAlert
		            $sl = $oevt1.Message.Length
                    Write-Host "$($oevt1.timeCreated): $($oevt1.Message.Substring(0, 127))..." -ForegroundColor Yellow
	            	if ($sl -le 254) { Write-Host "$($oevt1.Message.Substring(127))..." -ForegroundColor Yellow }
	            	else { Write-Host "$($oevt1.Message.Substring(127, 127))..." -ForegroundColor Yellow }
#                    Write-Host "$($oevt1.Message)" -ForegroundColor Yellow
##                    Write-Host "$($oevt1.timeCreated): $($oevt1.Message.Substring(0, 127))..." -ForegroundColor Yellow
##                    Write-Host "$($oevt1.Message.Substring(128, 254))..." -ForegroundColor Yellow
                } catch { WriteLine "Ok!" -colorOk }
            }

    
        #$os = Get-CimInstance Win32_OperatingSystem -ComputerName $srv
	    $os = Invoke-Command -Session $sess -ScriptBlock { Get-CimInstance Win32_OperatingSystem }

        $pctFree = [math]::Round(($os.FreePhysicalMemory/$os.TotalVisibleMemorySize)*100,2)

        Write-Host "Physical Memory Usage: " -NoNewline -ForegroundColor Cyan

        if ($pctFree -ge 45) { $Status = "OK"; WriteLine $Status -colorOk }
        elseif ($pctFree -ge 15 ) { $Status = "Warning"; Write-Host $Status -ForegroundColor Yellow }
        else { $Status = "Critical"; WriteLine $Status -colorAlert }


        $os | Select @{Name = "Free(%)"; Expression = {$pctFree}},
        @{Name = "Free(GB)";Expression = {[math]::Round($_.FreePhysicalMemory/1mb,2)}},
        @{Name = "Total(GB)";Expression = {[int]($_.TotalVisibleMemorySize/1mb)}} | ft -AutoSize

        if ($Status -ne "OK") {
            WriteLine "Top 3 processes:" -colorAlert
            
            $pp = Invoke-Command -Session $sess -ScriptBlock { Get-Process | sort ws -Descending | select -First 3 }

            $pp | select @{Name = "WS(GB)";Expression = {[math]::Round($_.WorkingSet64/1gb,2)}},
            @{Name = "WS(%)"; Expression = {[math]::Round(($_.WorkingSet64/1024/$os.TotalVisibleMemorySize)*100,2)}},
            @{Name = "ProcessName"; Expression = {$_.ProcessName}}, @{Name = "Description"; Expression = {$_.Description}} | ft -AutoSize
        }
            

    } else { WriteLine " - Offline" -colorAlert}
}

Get-PSSession | Remove-PSSession

"--------------------------------"
"Online servers: " + $aServersOnline.Count
"--------------------------------"

"Done!"
