$cred = Get-Credential
Connect-QADService -proxy vmww4618.mars-ad.net -Credential $cred 

$import = Import-CSV "C:\Scripts\DL_Script\DL_Addresses.csv" -delimiter ','
$group = Read-Host "Please type the DL email address to add or remove its members"


function Show-Dlmenu
{
     param (
           [string]$Title = 'DL add / remove members'
     )
     cls
     Write-Host "================ $Title ================"
     
     Write-Host "Press '1' for add members in DL."
     Write-Host "Press '2' for remove members in DL."
     Write-Host "Press 'Q' to quit."
}do{    Show-Dlmenu    $input = Read-Host "Please make a selection"    switch ($input) {   '1' {$import | ForEach-object {Add-QADGroupMember -Identity $group -member $_.email  }}   '2' {$import | ForEach-object {Remove-QADGroupMember -Identity $group -member $_.email }}   'Q' { return}}pause}until ($input -eq 'q')