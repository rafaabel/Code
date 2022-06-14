$cred = Get-Credential
Connect-QADService -proxy vmww4618.mars-ad.net -Credential $cred 

#Import CSV

$import = Import-CSV "C:\Scripts\DL_Script\DL_Addresses.csv" -delimiter ','
$group = "group_MWR_CStore_TSMs@effem.com"

#Remove Members
$import | ForEach-object {Remove-QADGroupMember -Identity $group -member $_.email } 		
	
