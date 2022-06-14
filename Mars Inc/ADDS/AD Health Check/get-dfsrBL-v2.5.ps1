#
#Version: 2.5
#
#Modified: 20.01.2020 (v2.5): 
# Added checking DFSR service is started
#
#Modified: 13.01.2020 (v2.4): 
# Added checking source DFSR service is started
#
#Modified: 21.03.2019 (v2.3): 
# Fixed restart DFSR service in the following conditions:
# (1) Condition #1
# Backlog Count > 99
# Example:
# Member <mjowrodc> Backlog File Count: 43029
#
#Modified: 12.11.2018 (v2.2): 
# Added restart DFSR service in the following conditions:
# (1) Condition #1
# Backlog Count > 100
# Example:
# Member <mjowrodc> Backlog File Count: 43029
#
#Author: anatoly.ivanitchev@effem.com
#

[CmdletBinding()]
Param ( [switch]$rwdcOnly )

#$srcDC = "isxdc102"
#$srcDC = "AZR-EUS2W5726"
$srcDC = "AZR-EUS2W6700"
$minOSversion = "2008 R2"

if ($rwdcOnly.IsPresent) { $flt = 'isReadOnly -eq $false' } else { $flt = '*' }

function check-DFSR ($computer) {
   Write-Host "Checking DFSR service..." -NoNewLine
   $srcStat = Get-Service "dfsr" -ComputerName $computer 
   $srcStat.status 
   if ( $srcStat.status -eq "Stopped") {
      Write-Host "DFSR service is stopped. Starting..." -ForegroundColor Red 
      $srcStat | Start-Service
      Write-Host "Wait for 15 sec to continue..." -ForegroundColor Yellow
      Sleep -Seconds 15
   } else { Write-Host " Ok." -ForegroundColor Green }
}

check-DFSR($srcDC) 
$oDCs = Get-ADDomainController -Filter $flt | sort isReadOnly, site, name
"--------------------------------"
"Total servers: " + $oDCs.Count

"--------------------------------"
#$srv = $oDCs[0]

#break

$scriptBlock01 = {
    param ($srcDC, $srvName)

    $error.Clear()

    $owf = dfsrdiag backlog /rgname:"Domain System Volume" /rfname:"SYSVOL Share" /sendingmember:$($srcDC)  /receivingmember:$($srvName)

    New-Object pscustomobject –property @{
        owf = $owf
        error = $error
    }
}


foreach ($srv in $oDCs) {

    Write-Host $srv.name 
    $srv.name = $srv.name.toLower()
    
    if (!$srv.name.Equals($srcDC)) {
	if (!($srv.OperatingSystem.Contains($minOSversion))) {
	    try {
                $odbfrBackLog = Get-DfsrBacklog -GroupName "Domain System Volume" -FolderName "SYSVOL Share" -SourceComputerName $srcDC -DestinationComputerName $srv.name -Verbose -ErrorAction Stop
	    } catch {
                check-DFSR($srv.name) 
                $odbfrBackLog = Get-DfsrBacklog -GroupName "Domain System Volume" -FolderName "SYSVOL Share" -SourceComputerName $srcDC -DestinationComputerName $srv.name -Verbose
	    } 
            if ($odbfrBackLog.Count -gt 99) { Write-Host "DFSR: restarting..." -ForegroundColor Yellow -NoNewLine
		Get-Service dfsr -ComputerName $srv.name | Restart-Service
		Write-Host " Done." -ForegroundColor Green } 
           
        } else {
            #Write-Host $srv.OperatingSystem
#	    $cmdLine = (dfsrdiag backlog /rgname:"Domain System Volume" /rfname:"SYSVOL Share" /sendingmember:$($srcDC)  /receivingmember:$($srv.name))
#	    Invoke-Command -ScriptBlock { $cmdLine }
	        $odbfrBackLog = Invoke-Command -ScriptBlock $scriptBlock01 -ArgumentList $srcDC, $srv.name
                    
            if ($odbfrBackLog.error) { continue }
            
            ##$odbfrBackLog.owf

            if (!($odbfrBackLog.owf -like "No Backlog*")) {
                $abl = $odbfrBackLog.owf[1].split(":").Trim()
                if ($abl.Count -eq 2) { 
                    [int]$blfCount = $abl[1]
                    if ($blfCount -gt 99) { Write-Host "DFSR: restarting..." -ForegroundColor Yellow -NoNewLine
			Get-Service dfsr -ComputerName $srv.name | Restart-Service
			Write-Host " Done." -ForegroundColor Green }            
                }
            }
      }
    }
}



