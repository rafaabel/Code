<#
.Synopsis
   Enable all inactive accounts from spreadsheet
.DESCRIPTION
   Enable all inactive accounts from spreadsheet
.REQUIREMENTS
   This script must be run locally from any DC
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
02 / 14 / 2022
#>


$users = Import-Csv -path "C:\Users\abelraf\OneDrive - Mars Inc\Documents\IDSS Team\Projects\ADDS\Trimarc Reports\RCAD_inactiveAccounts_11.02.2022.csv"

ForEach ($user in $users) {

    Enable-ADAccount -Identity $user.SamAccountName

    write-host "user $($user) has been enabled"

}