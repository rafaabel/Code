##Connection to ARS

$cred = Get-Credential
Connect-QADService -proxy vmww4618.mars-ad.net -Credential $cred 

#varialables 

$remove = @("Alessandro.Rizzelli@effem.com",
"Balaji.Achyouthan@effem.com",
"bhatt.niraj@effem.com",
"Eline.Apprederisse@effem.com",
"fred.albright@effem.com",
"kusha.shetty@effem.com",
"rajesh.thk@effem.com",
"Rakesh.Balani@effem.com",
"avisankar.pentapati@effem.com",
"ravisankar.pentapati1@effem.com",
"sree.harsha.jamjuru1@effem.com");

$add = @("Brenda.Sanchez@effem.com",
"Manuel.G.Garcia@effem.com");

#add and remove members

Foreach ($placeholderremove in $remove) {

	Remove-QADGroupMember -Identity GlobalImmediateMWC@effem.com -Member $placeholder 
}

Foreach ($placeholderadd in $add) {
    Add-QADGroupMember -Identity GlobalImmediateMWC@effem.com -Member $placeholderadd
}

