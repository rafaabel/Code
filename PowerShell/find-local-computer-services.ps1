<#
.Synopsis
   Script to get all services running in a computer
.DESCRIPTION
   Script to get all services running in a computer and under which account
.REQUIREMENTS
   This script must be run locally from any computer
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
09 / 22 / 2021
#>

Get-CmiObject -Class Win32_Service |
Select-Object Name, DisplayName, State, StartName | 
Export-Csv -NoTypeInformation "C:\Temp\find_services.csv"