##Connection to ARS

$cred = Get-Credential
Connect-QADService -proxy vmww4618.mars-ad.net -Credential $cred 

#Variables

$group = "Global Immediate MWC" 
$target = "apertrom"
$ArrDirectRep = [System.Collections.ArrayList]@(); 
$i = 0;

#Add Members
do{
    $_directreports = Get-QADUser $target -IncludeAllProperties | Select DirectReports -ExpandProperty DirectReports
foreach ($object in $_directreports) {
    $ArrDirectRep.Add($object);
}
$target = $ArrDirectRep[$i];
$i++;
}
while (($_directreports) -or ($i -le $ArrDirectRep.Count))

foreach ($user in $ArrDirectRep) {
Add-QADGroupMember -Identity $group -Member $user
}
  
 
