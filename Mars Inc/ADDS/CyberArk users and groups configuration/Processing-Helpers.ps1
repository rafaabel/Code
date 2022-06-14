#
#  Remove domain name from FQDN
#
Function TruncateFQDN
{
  Param ([String]$serverName)
  if(($serverName -match ".mars-ad.net") -or ($serverName -match ".rcad.net")){
    return $serverName.Split('.')[0]
  } else {
    return $serverName
  }
}
#
#  Validate computer name convention
#
Function ValidateServerName
{
  Param ([String]$serverName)
  return (($serverName.Length -le 15) -and ($serverName -match "^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$"))
}
#
#  Validate Listener name convention
#
Function ValidateListenerName
{
  Param ([String]$serverName)
  return (($serverName.Length -le 15) -and ($serverName -match "^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$"))
}
#
#  Validate CyberArk admin group
#
Function ValidateAdminGroup
{
  Param ([String]$GroupName)
  return ($GroupName -match "^EPV-[a-zA-Z0-9-_]*-Target[0-9]{3}$")
}
#
#  Returns percent of free space for C drive of specified server
#
Function GetCDrivePercentFree
{
  Param([String]$serverName,[System.Management.Automation.PSCredential]$credentials)
  $CDrive = Get-WmiObject Win32_LogicalDisk -ComputerName $serverName -Credential $credentials | Where-Object { $_.DriveType -eq "3" -and $_.DeviceID -eq "C:" } | Select-Object DeviceID, Freespace, Size
  return [math]::Round(($CDrive.Freespace / $CDrive.Size)*100)
}
#
#  Returns credentials of specified user having encrypted file with password and key
#
Function GetCredentials
{
  Param([String]$UserName,[String]$PasswordPath,[String]$KeyPath)
  $GetKey = Get-Content $KeyPath
  $SecureStringPassword = Get-Content -Path $PasswordPath | ConvertTo-SecureString -Key $GetKey
  $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName,$SecureStringPassword
  return $credentials
}