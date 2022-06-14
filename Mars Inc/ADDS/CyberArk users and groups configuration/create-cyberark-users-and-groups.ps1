#Script: Create CyberArk users and groups
#Author: Markus Rabello

#Connect to ARS
Connect-QADService -proxy vmww4618.mars-ad.net

#Create generic user accounts
for ($i = 101; $i -le 107; $i++) { $u = "EPV-RGUCAM-WNDD-" + $i ; New-QADUser $u -SamAccountName $u -UserPassword "xlVJX8jRUoZLmy6tve1l8uj" -FirstName $u -DisplayName $u -Description "User Account Used by CyberArk" -ParentContainer "OU=Access Users,OU=Hosting,OU=RC,DC=RCAD,DC=NET"; }

#Create TARGE100 group
New-QADGroup "EPV-APP-PRD-RGUCAM-01-Target100" -Description "EPV-APP-PRD-RGUCAM-01-Target100" -DisplayName "EPV-APP-PRD-RGUCAM-01-Target100" -GroupType Security -GroupScope Global -ParentContainer "OU=Access Groups,OU=Hosting,OU=RC,DC=RCAD,DC=NET"

#Adding generic user accounts to TARGET100 group
for ($i = 101; $i -le 107; $i++) { $u = "EPV-RGUCAM-WNDD-" + $i ; $us = get-qaduser $u -Service RCAD.NET ; get-qadgroup -Identity "EPV-APP-PRD-RGUCAM-01-Target100" -Service RCAD.NET | add-qadgroupmember -Member $us } $us = $null; $u = $null;





