#Script: Retrieve certificates requests by Certificate Templates
#Author: Rafael Abel
#Email: rafael.abel@effem.com
#Date: 11.03.2021
#Version: 1.0
#More details in https://www.pkisolutions.com/tools/pspki/
#CA servers: "Mars Inc ISXCA01", "Mars Inc ISXS187" and "Mars Inc MTOS894"

#Import PSKI Module
Import-Module PSPKI

#Store the information from every certificate issued by certificate template in the last 2 years into the array
[System.Collections.ArrayList]$certbytemplate = @(Get-CertificationAuthority -Name "Mars Inc ISXS187" `
 | Get-IssuedRequest -Filter "NotBefore -ge $((Get-Date).AddYears(-2))"`
  | select -ExpandProperty CertificateTemplate)

#Get every certificate by certificate template and find its respective friendly name
  $output = ForEach ($i in $certbytemplate)
    {

    Get-ObjectIdentifier $i 

    }

#Output the array content to the CSV File
    $output | Export-CsV 'D:\Scripts\retrieve_certificates_requests_by_certificate_templates.csv'

  




