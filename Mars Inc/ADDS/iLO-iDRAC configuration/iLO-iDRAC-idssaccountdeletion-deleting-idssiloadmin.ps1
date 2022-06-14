<#
.Synopsis
   Script to delete idssIloAdmin local account from iLO
.DESCRIPTION
   Script to delete idssIloAdmin local account from iLO
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
    13/09/2021
#>

#Declare Global Variables
$adminpassword = "adminpassword "<#Insert in this variable the IDSS local admin (<sitecode> + ilo + idssadmin) password. After completed, delete for security purposes#>
$deletecred = "idssiLoAdmin"
$iloidssadmin = "iloidssadmin"
$UsersDeletedFromiLO = "C:\Temp\UsersDeletedFromiLO.txt"
$UsersToBeDeletedManually = "C:\Temp\UsersToBeDeletedManually.txt"
$errorlog = "C:\Temp\errorlogidssaccountdeletion.txt"
$sources = Import-Csv -path "C:\Users\abelraf\OneDrive - Mars Inc\Documents\Identity and Directories\Projects\Scripts\ADDS_Scripts\DC_Script\Mars-AD iLO iDRAC.csv"
Function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date) 
}

Foreach ($source in $sources) {
    $sourcesitelowered = ($source.site).ToLower()

    #Check if model is HP (Pro) or any other. In case of any other, skip to the end of the script and log the server name"
    If ($source.model -like "Pro*") {

        #Create connection to iLO
        Try {
            $iloConnection = Connect-HPEiLO -Address $source.iLO -Username $sourcesitelowered$iloidssadmin -Password $adminpassword -DisableCertificateAuthentication
            If ($iloConnection) {
 
                #Check $deletecred account to see if exists. If exists, account will be deleted
                Write-host "Checking to see if $deletecred exists in iLO"      
                $accountcheck = $(Get-HPEiLOUser -Connection $iloConnection -LoginName $deletecred -erroraction 'silentlycontinue')
                Write-host "DNS Lookup Result [blank if not found]: $($accountcheck.LoginName)"

                If ("$($accountcheck.LoginName)" -match "$deletecred") {         
                    Write-host "$deletecred exists in iLO, deleting.." -ForegroundColor "Yellow" 
                    Remove-HPEiLOUser -Connection $iloConnection -LoginName $deletecred
                    Write-output "$($source.hostName) $deletecred " | out-file $UsersDeletedFromiLO  -Append
                    Write-host
                }
                Else {
                    Write-host "$deletecred does not exist. Please check again" -ForegroundColor "Red"
                    Write-host
                }
            }
            Else {
                Write-host "Not able to establish the connection to $($source.iLO), Skipping..." -ForegroundColor "Red"
                Write-host
                Write-output "$($source.hostName) $deletecred" | out-file $UsersToBeDeletedManually -Append
            } 
        }
        Catch {
            Write-host "An error has occurred that could not be resolved. Please check the logs for more information" -ForegroundColor "Red"
            Write-host
        }
    }
    Else {
        Write-host "$($source.hostName) is not a HP server (iLO). Please delete $deletecred manually" -ForegroundColor "Red"
        Write-host
        Write-output "$($source.hostName) $deletecred" | out-file $UsersToBeDeletedManually -Append
    }
    Write-output $(Get-TimeStamp)$error | out-file $errorlog
}



