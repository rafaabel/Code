#
#  .SYNOPSIS
#
#  AD-ActiveRoles-GrantAccess -ComputerName -AdminGroup -Ctask [-Username] [-SecPasswdPath] [-SecPasswdKeyPath] [-LogFile]
#
#  .DESCRIPTION
#
#  PowerShell script grants access to specified server for specified EPV group using specific credentials (username and password as secure string in file with key to decrypt).
#  Script will return following values for computer and group respectively delimeted by semicolon;
#  "Error loading Processing-Helpers.ps1" - Unable to load helper functions
#  "<ComputerName> name check failed" - If supplied Computer name doesnt comply with policy
#  "<AdminGroup> name check failed" - If supplied Admin group name doesnt comply with policy
#  "Unable to load ActiveRoles module" - Script was unable to load Active roles module
#  "Unable to establish connection with ActiveRoles" -script was unable to connect with ARS server
#  "Error creating <ComputerName> Administrators group" - EPV-<ComputerName>-Administrators group was not found and script was unable to create one
#  "Error adding <AdminGroup> to <ComputerName> Administrators" - Something went wrong adding admin group to server administrators
#  "Specified EPV group does not exist" - Script was unable to find specified admin group in domain which server belongs to
#  "Unable to resolve <ComputerName> from DNS" - Script was unable to resolve DNS
#  "Success" - Access granted

#
#  .PREREQUSITES
#
#  1. Download and install ActiveRoles 7.0 module from https://isx.depot.apps.mars/public/processing_windows/support/ActiveRoles70/, read MUST_READ.pptx slides before installation
#  2. Ensure password is saved as securestring to file and encryption key is written to another file, those paths should be passed as parameters or hardcoded as default values below
#
#  .EXAMPLE
#
#  Add NSAP team as Administrators for Computer1
#
#    .\AD-ActiveRoles-GrantAccess.ps1 -ComputerName "Computer1" -AdminGroup EPV-PLAT-PRD-NSAP-Target100 -Ctask CTASK12345678
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  Computer Name
#
   [Parameter(Mandatory=$True)]
   [string]$ComputerName,
#
#  Admin Group
#
   [Parameter(Mandatory=$True)]
   [string]$AdminGroup,
#
#  Change Task
#
   [Parameter(Mandatory=$True)]
   [string]$Ctask,
#
#  Username
#
   [Parameter(Mandatory=$False)]
   [string]$Username = "Mars-AD\svc_srv-commission",
#
#  Path to file containing password as secure string
#
   [Parameter(Mandatory=$False)]
   [string]$SecPasswdPath = "D:\tools\secpass\svc_srv-commission@mars-ad.net.regbak",
#
#  Encryption key
#
   [Parameter(Mandatory=$False)]
   [string]$SecPasswdKeyPath = "C:\Users\svc_srv-commission\etc\svc_srv-commission@mars-ad.net.key",
#
#  Logfile
#
   [Parameter(Mandatory=$False)]
   $LogFile = ($PSScriptRoot + '\GrantAccess\' + $ComputerName + '_' + $Ctask + '_' + (get-date -format "MM-d-yy-HH-mm") + '.log')
)
#
#  End of parameters block
#_______________________________________________________
#
#  Start logging
#
  Start-Transcript -Path $LogFile -Append | Out-Null
#_______________________________________________________
#  Start of functions block
#
#
# Importing functions
#
  try
  {
    .($PSScriptRoot + "\Processing-Helpers.ps1")
  }
  catch
  {
    Write-Output "<message>Error loading Processing-Helpers.ps1</message>"
    Stop-Transcript | Out-Null
    return -1
  }
#
#  End of functions block
#_______________________________________________________
#
# Pre-execution check
#
  $ComputerName = TruncateFQDN -serverName $ComputerName
  if(-not (ValidateServerName -serverName $ComputerName))
  {
    Write-Output "<message>$ComputerName name check failed</message>"
    Stop-Transcript | Out-Null
    return -1
  }
  if(-not (ValidateAdminGroup -GroupName $AdminGroup))
  {
    Write-Output "<message>$AdminGroup name check failed</message>"
    Stop-Transcript | Out-Null
    return -1
  }
#
# Identify server domain
#
  try
  {
    if([System.Net.Dns]::GetHostByName($ComputerName).HostName -like "*.rcad.net")
    {
      $Domain = "RCAD"
      $GroupContainer = "OU=Server Administrator Groups,OU=Hosting,OU=RC,DC=RCAD,DC=Net"
    }
    else
    {
      $Domain = "Mars-AD"
      $GroupContainer = "OU=Server Administrator Groups,OU=Hosting,OU=IT-Services,DC=Mars-AD,DC=Net"
    }
  }
  catch
  {
    Write-Output "<message>Unable to resolve $ComputerName from DNS</message>"
    Stop-Transcript | Out-Null
    return -1
  }
#
# Load Dell Active Roles Module
#
  try
  {
    Import-Module ActiveRolesManagementShell -WarningAction SilentlyContinue -ErrorAction Stop
  }
  catch
  {
    Write-Output "<message>Unable to load ActiveRoles module</message>"
    Stop-Transcript | Out-Null
    return -1
  }
#
# Constructing credentials
#
  $credentials = GetCredentials -UserName $Username -PasswordPath $SecPasswdPath -KeyPath $SecPasswdKeyPath
#
# Connect to Active Roles Service
#
  try
  {
    Connect-QADService -Proxy -Credential $credentials -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
  }
  catch
  {
    Write-Output "<message>Unable to establish connection with ActiveRoles</message>"
    Stop-Transcript | Out-Null
    return -1
  }
#
# Create Admin Group
#
  if(-not (Get-QADGroup -Identity "$Domain\EPV-$ComputerName-Administrators"))
  {
    try
    {
      New-QADGroup -Name "EPV-$ComputerName-Administrators" -SamAccountName "EPV-$ComputerName-Administrators" -Description "$ComputerName server Administrators" -ParentContainer $GroupContainer -GroupType 'Security' -GroupScope 'Global' | Out-Null
    }
    catch
    {
      Write-Output "<message>Error creating $ComputerName Administrators group</message>"
      Write-Output $_.Exception.Message
      Disconnect-QADService
      Stop-Transcript | Out-Null
      return -1
    }
  }
#
# Adding administrators
#
  if(Get-QADGroup -Identity "$Domain\$AdminGroup")
  {
    try
    {
      Add-QADGroupMember -Identity "$Domain\EPV-$ComputerName-Administrators" -member "$Domain\$AdminGroup" | Out-Null
      Write-Output "<message>Success</message>"
    }
    catch
    {
      Write-Output "<message>Error adding $AdminGroup to $ComputerName Administrators</message>"
      Write-Output $_.Exception.Message
      Disconnect-QADService
      Stop-Transcript | Out-Null
      return -1
    }
  }
  else
  {
    Write-Output "<message>Specified EPV group does not exist</message>"
  }
#
# Disconnect from Active Roles Service
#
  Disconnect-QADService
#
# Stop logging
#
  Stop-Transcript | Out-Null