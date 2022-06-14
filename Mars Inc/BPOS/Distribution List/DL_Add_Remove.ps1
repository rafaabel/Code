#Connection to ARS
$cred = Get-Credential
Connect-QADService -proxy vmww4618.mars-ad.net -Credential $cred 

#Function to choose the .csv file via open file dialog
Function Get-FileName

{
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null 
$OpenFileDialog= New-Object system.windows.forms.openfiledialog
$OpenFileDialog.InitialDirectory = "C:\"
$OpenFileDialog.filter = "CSV (*.csv)| *.csv"
$OpenFileDialog.showdialog() | Out-Null
$OpenFileDialog.filenames
}
	
   Write-Host "================== Add or Remove Distribution List members=================="
   Write-Host "Please select the CSV file" 
   Write-Host 
   Pause
   Write-Host 
 
$file= Get-FileName 
$import =  Import-CSV $file  -Delimiter ',' 

#Ask and verify if DL email address exists 
Do { 

$group = Read-Host "Please type the DL email address to add or remove its members"
$result = Get-QADGroup $group -IncludeAllProperties | select mail

If ($result -ne $null) {
Write-Host
Write-Host ("DL email address found")
Write-Host 
Pause
Write-Host 
}
Else {
Write-Host 
Write-Host ("DL email address not found. Please type again")
Write-Host 
}
}
While ($result -eq $null)


#Menu to add or remove members
Function Show-Dlmenu
{
     param ([string]$Title = 'Distribution List members')
     cls
     Write-Host "================ $Title ================"  
     Write-Host  
     Write-Host "Press '1' for add members in DL."
     Write-Host "Press '2' for remove members in DL."
     Write-Host "Press 'Q' to quit."
}do{    Show-Dlmenu    $input = Read-Host "Please make a selection"    Write-Host      Switch ($input) {   '1' {$import | ForEach-object {Add-QADGroupMember -Identity $group -member $_.email  }}   '2' {$import| ForEach-object {Remove-QADGroupMember -Identity $group -member $_.email }}   'Q' {return}}Pause}until ($input -eq 'q')

#Clear variables

Clear-Variable $file
Clear-Variable $group 
Clear-Variable $result

cls

Write-host 'Script completed!' 

