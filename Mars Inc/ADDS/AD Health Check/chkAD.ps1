
#.\check-orphanGPOs.ps1
.\get-replSum.cmd
#.\check-dnsARecordPropagation-v2.3.ps1 
#.\check-dnsARecordPropagation-v2.3.ps1 -dnsResolutionOnly saml.federation.effem.com
#"Waiting for replication for 7.5 mins"
#Start-Sleep 450
.\check-dnsARecordPropagation-v2.3.ps1 -rwdcOnly -dnsResolutionOnly -skipDnsReverseRR -dnsNameToTest appsldaplb.mars-ad.net
#.\check-dnsARecordPropagation-v2.3.ps1 -dnsResolutionOnly idssPropagationTest-04.mars-ad.net
#-dnsResolutionOnly
#.\get-dfsrBL.cmd
.\get-dfsrBL-v2.5.ps1

break
Write-Host "Checking pending reboot: RWDC" -NoNewline
$dcList = Get-ADDomainController -Filter 'isReadOnly -eq $false' | select -expandProperty name
.\test-pendingReboot -ComputerName $dcList -Detailed -SkipConfigurationManagerClientCheck | sort IsRebootPending, computerName | ft ComputerName, IsRebootPending, ComponentBasedServicing, PendingFileRenameOperations, WindowsUpdateAutoUpdate -AutoSize
#Write-Host "Checking pending reboot: RODC" -NoNewline
#$dcList = Get-ADDomainController -Filter 'isReadOnly -eq $true' | select -expandProperty name
#.\test-pendingReboot -ComputerName $dcList -Detailed -SkipConfigurationManagerClientCheck | sort IsRebootPending, computerName | ft ComputerName, IsRebootPending, ComponentBasedServicing, PendingFileRenameOperations, WindowsUpdateAutoUpdate -AutoSize

