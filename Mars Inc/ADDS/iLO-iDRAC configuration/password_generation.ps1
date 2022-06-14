<#
.Synopsis
   Script to generate password meeting the security policy
.DESCRIPTION
   It generates the password meeting the security policy
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
   Based on Steve Konig script
   https://activedirectoryfaq.com/2017/08/creating-individual-random-passwords/
.DATE
    09/16/2021
#>

#Function to get random characters
Function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs = ""
    return [String]$characters[$random]
}
 
#Function to scramble the strings
Function Set-String([string]$inputString) {     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}
#Function to generate the final password

$password = Get-RandomCharacters -length 20 -characters 'abcdefghiklmnoprstuvwxyz'
$password += Get-RandomCharacters -length 1 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
$password += Get-RandomCharacters -length 1 -characters '1234567890'
$password += Get-RandomCharacters -length 1 -characters '!"§$%/()=?}][{@#*+'
Write-Output $password
