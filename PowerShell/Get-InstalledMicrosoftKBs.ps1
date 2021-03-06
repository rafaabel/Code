
<#
.Synopsis
   Retrieve KB installed in every Domain Controller from local floreest
.DESCRIPTION
   The script verifies whether a particular update installed. If the update isn't installed, the computer name is written to a text file.
.REQUIREMENTS
   This script must be run with Domain Admin account rights
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
    05/11/2022
#>

$AllDCs = (Get-ADForest).Domains | % { Get-ADDomainController -Filter * -Server $_ }  | select HostName | Out-File -FilePath .\AllDCs.txt -NoClobber
$A = Get-Content -Path .\AllDCs.txt
$A | ForEach-Object { if (!(Get-HotFix -Id KB4534321 -ComputerName $_))
   { Add-Content $_ -Path .\Missing-KB45343215.txt } }
         

