
$NotifyMembers = [System.Collections.ArrayList]@(); 

$members = Get-QADGroupMember -Identity "notify@effem.com" -Indirect -Type "user" -SizeLimit 0

    foreach ($member in $members) {
        $member = Get-QADUser -Identity $member -SearchRoot "DC=Mars-AD,DC=Net" -IncludedProperties *;
        $Managers = [System.Collections.ArrayList]@(); 
        $_user = $member
        do{
        $user = Get-QADUser -Identity $_user -SearchRoot "DC=Mars-AD,DC=Net";
        $manager = $user.Manager
        if($manager -ne $null){
        $Managers.add($(Get-QADUser $manager).DisplayName);
        }
        $_user = $manager
        } while ($manager -ne $null);

        $_member = [PSCustomObject]@{
            Name = $member.DisplayName
            Segment = "$($member.marsCustomAttribute2) ($($member.Department))"
            Email = $member.mail
            Managers = $Managers -join "|"
        }

        $NotifyMembers.add($_member)

        }


foreach ($member in $NotifyMembers){ $member | select Name, Email, Segment, Managers | Export-Csv -Path "C:\Temp\Notify.csv" -Append -Delimiter ';' -NoTypeInformation} 
 
