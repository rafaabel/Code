##Connection to ARS

$cred = Get-Credential
Connect-QADService -proxy vmww4618.mars-ad.net -Credential $cred 

#Variables

$targets = @(
@("Global Immediate MWC","APERTROM")

)

Foreach ($target in $targets) {

$groupname =  $target[0]
$targetuser = $target[1]
$properties = @(
"SamAccountName",
"Mail", 
"DisplayName"
"DirectReports")

#Lookup Direct Reports

$aduser = Get-QADUser -Identity $targetuser -Properties $properties | Select SamAccountName, Mail, Displayname, @{n='DirectReports';e={$_.DirectReports -join '; '}} 

#Create Group
New-QADGroup -Name $groupname -DisplayName $groupname  -GroupType Distribution -GroupScope Global  -ParentContainer "OU=Distribution Lists,OU=Mars,OU=Exchange,OU=IT-Services,DC=Mars-AD,DC=Net"
Set-QADGroup -Identity $groupname  -Email "$($groupname -replace ' ','')@$($aduser.mail.split('@')[1])" -ObjectAttributes @{ targetaddress="smtp:$($groupname -replace ' ','')@mars.onmicrosoft.com"; SamAccountName=$($groupname -replace ' ','');} -Notes "Direct Reports of $($aduser.DisplayName)" 


#Add Members
    Foreach ($user in $aduser.DirectReports.Split(";")) {
        Add-QADGroupMember -Identity $groupname -member $user
    }
}


