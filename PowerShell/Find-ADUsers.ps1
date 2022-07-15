<#
.Synopsis
   Script to get all users by OU
.DESCRIPTION
   Script to get all users by OU
.REQUIREMENTS
   This script must be run locally from any computer
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
   Based on "netwrix" script
   https://www.netwrix.com/how_to_get_all_users_from_a_specific_ou.html
   Based on "TechNet"
   https://social.technet.microsoft.com/wiki/contents/articles/32418.active-directory-troubleshooting-server-has-returned-the-following-error-invalid-enumeration-context.aspx
.DATE
09/22/2021
#>

$ExportPath = 'C:\Temp\find_users_in_AD.csv'
$ADObjects = Get-ADUser -Properties * -Filter '
    extensionAttribute15 -eq "SITECODE" -or 
    extensionAttribute15 -eq "SITECODE" -or 
    extensionAttribute15 -eq "SITECODE"'

$ADObjects | Select-Object DistinguishedName, Name, UserPrincipalName, Mail, Enabled, extensionAttribute15 | 
Export-Csv -NoType $ExportPath
