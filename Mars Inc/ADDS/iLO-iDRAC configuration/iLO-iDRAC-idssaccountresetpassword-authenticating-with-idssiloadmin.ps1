<#
.Synopsis
   Script to reset IDSS local admin (<sitecode> + ilo + idssadmin) password authenticating with idssiLoAdmin
.DESCRIPTION
   Script to reset IDSS local admin (<sitecode> + ilo + idssadmin) password authenticating with idssiLoAdmin
   Also, it resets using fixed password for all accounts based on $newpassword variable
.REQUIREMENTS
   Source file "Mars-AD iLO iDRAC.csv"
   Install HPE Scripting Tools for Windows PowerShell
    - https://buy.hpe.com/us/en/software/infrastructure-management-software/system-server-management-software/system-server-software-management-software/scripting-tools-for-windows-powershell/p/5440657
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
$UsersPasswordResetIniLO = "C:\Temp\UsersPasswordResetIniLO.txt"
$UsersPasswordToBeResetManuallyIniLO = "C:\Temp\UsersPasswordToBeResetManuallyIniLO.txt"
$errorlog = "C:\Temp\errorlogidssresetpassword.txt"
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
 
                    #Check idsssiloadmin account to see if exists. If does not, skip
                    write-host "Checking to see if $sourcesitelowered$iloidssadmin exists in iLO"      
                    $accountcheck = $(Get-HPEiLOUser -Connection $iloConnectionRO -LoginName $sourcesitelowered$iloidssadmin -erroraction 'silentlycontinue')
                    write-host "DNS Lookup Result [blank if not found]: $($accountcheck.LoginName)"

                    #Generate new password
                    If ("$($accountcheck.LoginName)" -match "$sourcesitelowered$iloidssadmin") {         
                        Write-host "Reseting $sourcesitelowered$iloidssadmin password" -ForegroundColor "Green" 
                        Set-HPEiLOUser -Connection $iloConnectionRO -LoginName $sourcesitelowered$iloidssadmin -NewPassword $newpassword
                        Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersPasswordResetIniLO  -Append
                        Write-host
                    }
                    Else {
                        Write-host "User does not exist" -ForegroundColor "Red"
                        Write-host
                    }
                }
                Else {
                    Write-host "Not able to establish the connection to $($source.iLO), Skipping..." -ForegroundColor "Red"
                    Write-host
                    Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersPasswordToBeResetManuallyIniLO  -Append
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
      
                    #Check idsssiloadmin account to see if exists. If does not, skip
                    write-host "Checking to see if $sourcesitelowered$iloidssadmin exists in iLO"      
                    $accountcheck = $(Get-HPEiLOUser -Connection $iloConnectionRW -LoginName $sourcesitelowered$iloidssadmin -erroraction 'silentlycontinue')
                    write-host "DNS Lookup Result [blank if not found]: $($accountcheck.LoginName)"

                    If ("$($accountcheck.LoginName)" -match "$sourcesitelowered$iloidssadmin") {         
                        Write-host "Reseting $sourcesitelowered$iloidssadmin password" -ForegroundColor "Green" 
                        Set-HPEiLOUser -Connection $iloConnectionRW -LoginName $sourcesitelowered$iloidssadmin -NewPassword $newpassword
                        Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersPasswordResetIniLO  -Append
                        Write-host
                    }
                    Else {
                        Write-host "User does not exist" -ForegroundColor "Red"
                        Write-host
                    }
                }
                Else {
                    Write-host "Not able to establish the connection to $($source.iLO), Skipping..." -ForegroundColor "Red"
                    Write-host
                    Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersPasswordToBeResetManuallyIniLO  -Append
                    
                }
            }
            Catch {
                Write-host "An error has occurred that could not be resolved. Please check the logs for more information" -ForegroundColor "Red"
                Write-host
            }
        }
    }
    Else {
        Write-host "$($source.hostName) is not a HP server (iLO) Skipping..." -ForegroundColor "Red"
        Write-host
        Write-output "$($source.hostName) $sourcesitelowered$iloidssadmin" | out-file $UsersPasswordToBeResetManuallyIniLO  -Append
        
    }
    Write-output $(Get-TimeStamp)$error | out-file $errorlog
}