<#
.Synopsis
   Script to retrieve and create DNS records for iLO and iDRAC
.DESCRIPTION
   Script to retrieve and create DNS records for iLO and iDRAC. 
   It checks first if the iLO or iDRAC DNS record exists. If it does not, it creates a new record appending iLO or iDRAC to the hostname in Mars-AD.net zone
.REQUIREMENTS
   Source file "Mars-AD iLO iDRAC.csv"
   This script must be run locally from any DC in F:\ drive
   Steps to execute:
    - Fill the server information as the example in the first line (GUADC101) in "Mars-AD iLO iDRAC.csv". Do not forget to remove the example before executing the script. 
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
    09/09/2021
#>

#Declare Global Variables
$ZoneName = "mars-ad.net"
$ilo = "ilo"
$idrac = "idrac"
$ServersExistInDNS = "C:\Temp\ServersExistInDNS.txt"
$ServersAddedToDNS = "C:\Temp\ServersAddedToDNS.txt"
$errorlog = "C:\Temp\errorlogdnscreation.txt"
$DNSRecords = Import-Csv -path "F:\Mars-AD iLO iDRAC.csv"
Function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date) 
}

Foreach ($DNSRecord in $DNSRecords) {

    #Check if model is HP (Pro) or any other. In case of any other, DNS record will be created as "idrac"
    If ($DNSRecord.model -like "Pro*") {

        #Check DNS record to see if exists. If does not, create DNS record. 
        Write-host "Checking to see if $($DNSRecord.hostName)$ilo exists in DNS"          
        $DNSCheck = $(Get-DnsServerResourceRecord -name "$($DNSRecord.hostName)$ilo" -ZoneName $ZoneName -erroraction 'silentlycontinue'  | Where-Object { $_.Timestamp -eq $null } | select-object hostName)
        Write-host "DNS Lookup Result [blank if not found]: $($DNSCheck.HostName)"

        If ("$($DNSCheck.HostName)$ilo" -match "$($DNSRecord.HostName)$ilo") {         
            Write-host "$($DNSRecord.hostName)$ilo $($DNSRecord.iLO) exists in DNS, Skipping..." -ForegroundColor "Green" 
            Write-output "$($DNSRecord.hostName)$ilo $($DNSRecord.iLO)" | out-file $ServersExistInDNS -Append
            Write-host
        }
        Else { 
            Write-host "$($DNSRecord.hostName)$ilo $($DNSRecord.iLO) does not exist in DNS. Adding $($DNSRecord.hostName)$ilo $($DNSRecord.iLO) in DNS" -ForegroundColor "Yellow"
            Write-output "$($DNSRecord.hostName)$ilo $($DNSRecord.iLO)" | out-file $ServersAddedToDNS -Append
            Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name "$($DNSRecord.hostName)$ilo" -AllowUpdateAny -IPv4Address $($DNSRecord.iLO)
            Write-host
        }
    }
    Else {
        #Check DNS record to see if exists. If does not, create DNS record. 
        Write-host "Checking to see if $($DNSRecord.hostName)$idrac exists in DNS"          
        $DNSCheck = $(Get-DnsServerResourceRecord -name "$($DNSRecord.hostName)$idrac" -ZoneName $ZoneName -erroraction 'silentlycontinue'  | Where-Object { $_.Timestamp -eq $null } | select-object hostName)
        Write-host "DNS Lookup Result [blank if not found]: $($DNSCheck.HostName)"

        If ("$($DNSCheck.HostName)$idrac" -match "$($DNSRecord.HostName)$idrac") {         
            Write-host "$($DNSRecord.hostName)$idrac $($DNSRecord.iLO) exists in DNS, Skipping..." -ForegroundColor "Green" 
            Write-output "$($DNSRecord.hostName)$idrac $($DNSRecord.iLO)" | out-file $ServersExistInDNS -Append
            Write-host
        }
        Else { 
            Write-host "$($DNSRecord.hostName)$idrac $($DNSRecord.iLO) does not exist in DNS. Adding $($DNSRecord.hostName)$idrac $($DNSRecord.iLO) in DNS" -ForegroundColor "Yellow"
            Write-output "$($DNSRecord.hostName)$idrac $($DNSRecord.iLO)" | out-file $ServersAddedToDNS -Append
            Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name "$($DNSRecord.hostName)$idrac" -AllowUpdateAny -IPv4Address $($DNSRecord.iLO)
            Write-host
        }
    }
    Write-output $(Get-TimeStamp)$error | out-file $errorlog
}