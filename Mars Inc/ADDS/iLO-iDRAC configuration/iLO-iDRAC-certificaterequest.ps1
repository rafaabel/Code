<#
.Synopsis
   Script to request and install certificates in iLO
.DESCRIPTION
   Script to request and install certificates in iLO
   It has two functions, one to generate the CSR file from iLO and request the certificate and other to retrieve the approved request and install the certificate in iLO
.REQUIREMENTS
   Source file "Mars-AD iLO iDRAC - RequestID.csv"
   Install HPE Scripting Tools for Windows PowerShell:
    - https://buy.hpe.com/us/en/software/infrastructure-management-software/system-server-management-software/system-server-software-management-software/scripting-tools-for-windows-powershell/p/5440657
   Steps to execute:
    - Fill the server information as the example in the first line (GUADC101) in "Mars-AD iLO iDRAC - RequestID.csv". Do not forget to remove the example before executing the script. 
    - Run "Request-iLOCertificate" first. Then, get the RequesIDs generated from "C:\Temp\RequestID.txt" and share with CA owner to approve. 
    - Once is approved, open the source spreadsheet "Mars-AD iLO iDRAC - RequestID.csv" and put the RequestID number under "RequestID" column. 
    - Finally, set this new source in the $source variable in "Install-iLOCertificate" function and run it.
.EXAMPLES
    Request-iLOCertificate
    Install-iLOCertificate
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
   Based on Colin Westwater script
   https://www.vgemba.net/microsoft/powershell/iLO-SSL-Certificates
.DATE
    09/14/2021
#>

#Global Global Variables
$marscaISXS187 = "DC = Net, DC = Mars-AD, CN = Mars Inc ISXS187"
$marscaMTOS894 = "DC = Net, DC = Mars-AD, CN = Mars Inc MTOS894"
$marscaISXCA01 = "DC = Net, DC = Mars-AD, CN = Mars Inc ISXCA01"
$ZoneName = "mars-ad.net"
$ilo = "ilo"
$adminpassword = "adminpassword" <#Insert in this variable the IDSS local admin (<sitecode> + ilo + idssadmin) password. After completed, delete for security purposes#>
$iloidssadmin = "iloidssadmin"
$password = ConvertTo-SecureString -String $adminpassword -AsPlainText -Force
$errorlog = "C:\Temp\errorlogcertificaterequest.txt"

Function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date) 
}
Function Request-iLOCertificate {
 
    $requestid = "C:\Temp\RequestID.txt"
    $NoMarsCACertificatesInstalledIniLO = "C:\Temp\NoMarsCACertificatesInstalledIniLO.txt"
    $MarsCACertificatesInstalledIniLO = "C:\Temp\MarsCACertificatesInstalledIniLO.txt"
    $CertificatesToBeRequestedManually = "C:\Temp\CertificatesToBeRequestedManually.txt"
    $sources = Import-Csv -path "C:\Users\abelraf\OneDrive - Mars Inc\Documents\Identity and Directories\Projects\Scripts\ADDS_Scripts\DC_Script\Mars-AD iLO iDRAC - RequestID.csv"
 
    #Create the login credential object
    Foreach ($source in $sources) {
        $sourcesitelowered = ($source.site).ToLower()
        $sourceservernamelowered = ($source.hostName).ToLower()

        #Check if model is HP (Pro) or any other. In case of any other, skip to the end of the script and log the server name"
        If ($source.model -like "Pro*") {

            $username = $sourcesitelowered + $iloidssadmin
            $username
            $credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $username, $password
            $iloservername = "$sourceservernamelowered$ilo.$ZoneName"

            #Connect to the iLO:
            Try {
                $iloConnection = Connect-HPEiLO -credential $credential -IP $source.iLO -DisableCertificateAuthentication
            
                If ($iloConnection) {

                    #Check the default certificate details
                    Write-Host "Checking the current certificate installed... " -ForegroundColor "Yellow"
                    $CertDetails = Get-HPEiLOSSLCertificateInfo -Connection $iloConnection -OutputType RawResponse
                    $String = $CertDetails.ToString()
                    $Start = $String.IndexOf("Response:") + 9
                    $String = $String.Substring($Start, $String.Length - $Start)
                    $jsonObj = ConvertFrom-Json $String
                    $CertDetails = $jsonObj.X509CertificateInformation
                    $CertDetails | Out-Host
               
                    #Generate Certificate Signing Request from iLO
                    If ($certDetails.Issuer -ne $marscaISXS187 -or $certDetails.Issuer -ne $marscaMTOS894 -or $certDetails.Issuer -ne $marscaISXCA01) {
                        Write-Host "Generating new Certificate Signing Request... " -ForegroundColor "Yellow"
                        Start-HPEiLOCertificateSigningRequest -Connection $iloConnection `
                            -CommonName $iloservername `
                            -OrganizationalUnit "Mars Information Services" `
                            -Organization "Mars Inc." `
                            -City "McLean" `
                            -State "Virginia" `
                            -Country "US" `
                            -IncludeiLOIP

                        Start-sleep -Seconds 90
                        $csr = Get-HPEiLOCertificateSigningRequest -Connection $iloConnection
                        $csr | Out-File -FilePath "C:\Temp\$($iloservername)_csr.csr"

                        #Request certificate from CA and log the Request ID to be shared with CA owner for approval
                        $certreqid = certreq.exe -config "VMWW4707.mars-ad.net\Mars Inc ISXCA01" -submit -f -attrib "CertificateTemplate:MarsWebServicesSSL&ClientAuthenticationv1" C:\Temp\$($iloservername)_csr.csr
                        $certreqidstring = $certreqid | select-string -Pattern RequestID
                        write-output "$iloservername $certreqidstring" | Out-File $requestid -Append
                       
                        $CertDetails | Out-File -FilePath $NoMarsCACertificatesInstalledIniLO -Append
                    }
                    Else {
                        Write-host "The certificate installed in $iloservername is already issued by Mars CA, Skipping..." -ForegroundColor "Red"
                        $CertDetails | Out-File -FilePath $MarsCACertificatesInstalledIniLO -Append 
                        Write-host
                    }
                }
                Else {
                    Write-host "Not able to establish the connection to $($source.iLO), Skipping..." -ForegroundColor "Red"
                    Write-host
                    Write-output "$($source.hostName)" | Out-File $CertificatesToBeRequestedManually -Append
                }
            }
            Catch {
            }
        }
        Else {
            Write-host
            Write-host "$($source.hostName) is not a HP server (iLO). Please create request and enroll the certificate manually" -ForegroundColor "Red"
            Write-host
            Write-output "$($source.hostName)" | Out-File $CertificatesToBeRequestedManually -Append
        } 
        Write-output $(Get-TimeStamp)$error | out-file $errorlog
    }
}
Function Install-iLOCertificate {
    $NewCertificatesInstalledIniLO = "C:\Temp\NewCertificatesInstalledIniLO.txt"
    $CertificatesToBeInstalledManually = "C:\Temp\CertificatesToBeInstalledManually.txt"
    $sources = Import-Csv -path "C:\Users\abelraf\OneDrive - Mars Inc\Documents\Identity and Directories\Projects\Scripts\ADDS_Scripts\DC_Script\Mars-AD iLO iDRAC - RequestID.csv"

    #Create the login credential object
    Foreach ($source in $sources) {
        $sourcesitelowered = ($source.site).ToLower()
        $sourceservernamelowered = ($source.hostName).ToLower()

        #Check if model is HP (Pro) or any other. In case of any other, skip to the end of the script and log the server name"
        If ($source.model -like "Pro*") {

            $username = $sourcesitelowered + $iloidssadmin
            $credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $username, $password
            $iloservername = "$sourceservernamelowered$ilo.$ZoneName"

            #Connect to the iLO:
            Try {
                $iloConnection = Connect-HPEiLO -credential $credential -IP $source.iLO -DisableCertificateAuthentication
                If ($iloConnection) {

                    #Check the default certificate details
                    Write-Host "Checking the current certificate installed... " -ForegroundColor "Yellow"
                    $CertDetails = Get-HPEiLOSSLCertificateInfo -Connection $iloConnection -OutputType RawResponse
                    $String = $CertDetails.ToString()
                    $Start = $String.IndexOf("Response:") + 9
                    $String = $String.Substring($Start, $String.Length - $Start)
                    $jsonObj = ConvertFrom-Json $String
                    $CertDetails = $jsonObj.X509CertificateInformation
                    $CertDetails | Out-Host
     
                    If ($certDetails.Issuer -ne $marscaISXS187 -or $certDetails.Issuer -ne $marscaMTOS894 -or $certDetails.Issuer -ne $marscaISXCA01) {

                        #Retrieve approved certificate and install in iLO
                        Write-Host "Retrieving approved certificate and installing in iLO..." -ForegroundColor "Yellow"
                        certreq.exe -config "VMWW4707.mars-ad.net\Mars Inc ISXCA01" -retrieve $source.RequestID C:\Temp\$($iloservername)_pem.pem
                        $cert = Get-Content C:\Temp\$($iloservername)_pem.pem | Out-String
                        Import-HPEiLOCertificate -Certificate $cert -Connection $iloConnection
                        Start-sleep -Seconds 90

                        #Check the the new certificate details
                        Write-Host "Certificate installed" -ForegroundColor "Green"
                        $CertDetails = Get-HPEiLOSSLCertificateInfo -Connection $iloConnection -OutputType RawResponse
                        $String = $CertDetails.ToString()
                        $Start = $String.IndexOf("Response:") + 9
                        $String = $String.Substring($Start, $String.Length - $Start)
                        $jsonObj = ConvertFrom-Json $String
                        $CertDetails = $jsonObj.X509CertificateInformation
                        $CertDetails | Out-Host
                        $CertDetails | Out-File -FilePath $NewCertificatesInstalledIniLO -Append
                    }
                }
                Else {
                    Write-host "Not able to establish the connection to $($source.iLO), Skipping..." -ForegroundColor "Red"
                    Write-host
                    Write-output "$($source.hostName)" | Out-File $CertificatesToBeInstalledManually  -Append
                }
            }
            Catch {
            }
        }
        Else {
            Write-host
            Write-host "$($source.hostName) is not a HP server (iLO). Please create install the certificate manually" -ForegroundColor "Red"
            Write-host
            Write-output "$($source.hostName)" | Out-File $CertificatesToBeInstalledManually  -Append
        } 
        Write-output $(Get-TimeStamp)$error | out-file $errorlog 
    }
}   