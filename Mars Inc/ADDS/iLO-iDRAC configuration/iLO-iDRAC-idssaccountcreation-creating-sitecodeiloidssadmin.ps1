<#
.Synopsis
   Script to create the new IDSS local admin accounts for iLO following the name convention <sitecode> + ilo + idssadmin
.DESCRIPTION
   Script to create the new IDSS local admin accounts for iLO following the name convention <sitecode> + ilo + idssadmin
.REQUIREMENTS
   Source file "Mars-AD iLO iDRAC.csv"
   Install HPE Scripting Tools for Windows PowerShell:
    - https://buy.hpe.com/us/en/software/infrastructure-management-software/system-server-management-software/system-server-software-management-software/scripting-tools-for-windows-powershell/p/5440657
    Steps to execute:
    - Fill the server information as the example in the first line (GUADC101) in "Mars-AD iLO iDRAC.csv". Do not forget to remove the example before executing the script. 
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
   Based on Colin Westwater script
   https://www.vgemba.net/microsoft/powershell/HPE-ProLiant-iLO-Configuration-using-PowerShell/
.DATE
    09/09/2021
#>

#Declare Global Variables
$credro = Get-Credential -UserName idssiLoAdmin -Message "Enter current administrator iLO password for RODC"
$credrw = Get-Credential -UserName idssiLoAdmin -Message "Enter current administrator iLO password for RWDC"
$credroasstring = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credro.Password ))
$credrwasstring = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credrw.Password ))
$newpassword = "newpassword" <#Insert in this variable the IDSS local admin account (<sitecode> + ilo + idssadmin) new password. After completed, delete for security purposes#>
$iloidssadmin = "iloidssadmin"
$UsersExistIniLO = "C:\Temp\UsersExistIniLO.txt"
$UsersAddedToiLO = "C:\Temp\UsersAddedToiLO.txt"
$UsersRemovedFromiLO = "C:\Temp\UsersRemovedFromiLO.txt"
$UsersToBeAddedManually = "C:\Temp\UsersToBeAddedManually.txt" 
$errorlog = "C:\Temp\errorlogidssaccountcreation.txt"
$sources = Import-Csv -path "C:\Users\abelraf\OneDrive - Mars Inc\Documents\Identity and Directories\Projects\Scripts\ADDS_Scripts\DC_Script\Mars-AD iLO iDRAC.csv"
Function Get-TimeStamp {
   return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date) 
}

Foreach ($source in $sources) {
   $sourcesitelowered = ($source.site).ToLower()

   #Check if model is HP (Pro) or any other. In case of any other, skip to the end of the script and log the server name"
   If ($source.model -like "Pro*") {

      #Check if server is RODC. If does not, it requests RWDC credentials
      If ($source.hostName -like $($source.site + "*WRODC*")) {

         #Create connection to RODC iLO
         Try {
            $iloConnectionRO = Connect-HPEiLO -Address $source.iLO -Username $credro.UserName -Password $credroasstring -DisableCertificateAuthentication
            If ($iloConnectionRO) {
 
               #Check idsssiloadmin account to see if exists. If does not, account will be created
               Write-host "Checking to see if $sourcesitelowered$iloidssadmin exists in iLO"      
               $accountcheck = $(Get-HPEiLOUser -Connection $iloConnectionRO -LoginName $sourcesitelowered$iloidssadmin -erroraction 'silentlycontinue')
               Write-host "DNS Lookup Result [blank if not found]: $($accountcheck.LoginName)"

               If ("$($accountcheck.LoginName)" -match "$sourcesitelowered$iloidssadmin") {         
                  Write-host "$sourcesitelowered$iloidssadmin exists in iLO, Skipping..." -ForegroundColor "Green" 
                  Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersExistIniLO  -Append
                  Write-host
               }
               Else {
                  #Add the standard admin account with the network password
                  Write-host "Adding new $sourcesitelowered$iloidssadmin user account..." -ForegroundColor "Yellow"
                  Add-HPEiLOUser -Connection $iloConnectionRO -Username $sourcesitelowered$iloidssadmin -LoginName $sourcesitelowered$iloidssadmin -Password $newpassword -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes 
                  Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersAddedToiLO -Append

                  #Remove the built in default Administrator account
                  Write-host 'Removing the built in default Administrator account...' -ForegroundColor "Yellow"
                  Remove-HPEiLOUser -Connection $iloConnectionRO -LoginName Administrator
                  Write-output "$($source.hostName) Administrator" | out-file $UsersRemovedFromiLO -Append
                  Write-host
               }
            }
            Else {
               Write-host "Not able to establish the connection to $($source.iLO), Skipping..." -ForegroundColor "Red"
               Write-host
               Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersToBeAddedManually -Append
            } 
         }
         Catch {
            Write-host "An error has occurred that could not be resolved. Please check the logs for more information" -ForegroundColor "Red"
            Write-host
         }
      }
      Else {
         #Create connection to RWDC iLO
         Try {
            $iloConnectionRW = Connect-HPEiLO -Address $source.iLO -Username $credrw.UserName -Password $credrwasstring  -DisableCertificateAuthentication

            If ($iloConnectionRW) {
 
               #Check idsssiloadmin account to see if exists. If does not, account will be created
               Write-host "Checking to see if $sourcesitelowered$iloidssadmin exists in iLO"      
               $accountcheck = $(Get-HPEiLOUser -Connection $iloConnectionRW -LoginName $sourcesitelowered$iloidssadmin -erroraction 'silentlycontinue')
               Write-host "DNS Lookup Result [blank if not found]: $($accountcheck.LoginName)"

               If ("$($accountcheck.LoginName)" -match "$sourcesitelowered$iloidssadmin") {         
                  Write-host "$sourcesitelowered$iloidssadmin exists in iLO, Skipping..." -ForegroundColor "Green" 
                  Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersExistIniLO -Append
                  Write-host
               }
               Else {
                  #Add the standard admin account with the network password
                  Write-host "Adding new $sourcesitelowered$iloidssadmin user account..." -ForegroundColor "Yellow"
                  Add-HPEiLOUser -Connection $iloConnectionRW -Username $sourcesitelowered$iloidssadmin -LoginName $sourcesitelowered$iloidssadmin -Password $newpassword -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes
                  Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersAddedToiLO -Append

                  #Remove the built in default Administrator account
                  Write-host 'Removing the built in default Administrator account...' -ForegroundColor "Yellow"
                  Remove-HPEiLOUser -Connection $iloConnectionRW -LoginName Administrator
                  Write-output "$($source.hostName) Administrator" | out-file $UsersRemovedFromiLO -Append
                  Write-host
               }  
            }
            Else {
               Write-host "Not able to establish the connection to $($source.iLO), Skipping..." -ForegroundColor "Red"
               Write-host
               Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersToBeAddedManually -Append
            } 
         }
         Catch {
            Write-host "An error has occurred that could not be resolved. Please check the logs for more information" -ForegroundColor "Red"
            Write-host
         }
      }
   }
   Else {
      Write-host "$($source.hostName) is not a HP server (iLO). Please add $sourcesitelowered$iloidssadmin and remove built in default Administrator or Root account manually" -ForegroundColor "Red"
      Write-host
      Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersToBeAddedManually -Append
   }
   Write-output $(Get-TimeStamp)$error | out-file $errorlog
}
