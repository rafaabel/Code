<#
.Synopsis
   Script to get and set DNS servers values in DHCP scopes
.DESCRIPTION
   Script to get and set DNS servers values in DHCP scopes
.REQUIREMENTS
   This script msut be run from any DC like azr-eus2w5648.mars-ad.net
   Spreadsheet with DHCP content like attached in CHG0190799
.AUTHOR
   Anatoly Ivanitchev - Anatoly.Ivanitchev@effem.com
#>

#Run below script to validate the DNS servers for all DHCP scopes

# Change the source fine name accordingly (files attached)
$srcfile = "f:\mtoRetire\dhcp-local.csv"  

#To get DHCP 006 DNS Servers option values:
Import-Csv $srcfile | % { 
    $_.serverName + ": " + $_.scopeId
    Get-DhcpServerv4OptionValue -ComputerName $_.serverName -ScopeId $_.scopeId -OptionId 006 
} | format-table scopeId, Value -AutoSize


# Change the source fine name accordingly (files attached)
$srcfile = "f:\mtoRetire\dhcp-local.csv"  

#To set a new 006 DNS Servers DHCP scope option value:
Import-Csv $srcfile | % { 
    $_.serverName + ": " + $_.scopeId
    [string[]]$newoptValue = $_.newoptionValue.Trim().Split(" ")
    $newoptValue
    Set-DhcpServerv4OptionValue -ComputerName $_.serverName -ScopeId $_.scopeId -OptionId 006 -Value $newoptValue -WhatIf
}
