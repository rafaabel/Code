Connect-QADService -proxy vmww4618.mars-ad.net -Credential $(Get-Credential)

$dls = @('RC-WW-BP-IT');

$BPMembers = [System.Collections.ArrayList]@();

foreach ($dl in $dls) {
    $members = Get-QADGroupMember -Identity $dl -Type "user" -Indirect -SizeLimit 0
    foreach ($member in $members) {
        $BPMembers.add($member)
        }
}

foreach ($member in $BPMembers) {
    Remove-QADGroupMember -Identity "notify@effem.com" -Member $member 
}