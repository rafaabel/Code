Get-QADGroupMember GlobalImmediateMWC@effem.com | select name, email, @{N='Manager';E={(Get-QADUser $_.Manager).Name}} | Export-Csv C:\Temp\GlobalImmediateMWC.csv
