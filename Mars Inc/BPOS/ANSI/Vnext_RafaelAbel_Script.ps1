$creds = get-credential 
Import-PSSession(New-PSSession -name Rafael -ConfigurationName Microsoft.Exchange -ConnectionUri https://o365.mail.effem.com/powershell-liveid/ -Authentication Basic -Credential $creds -AllowRedirection) 