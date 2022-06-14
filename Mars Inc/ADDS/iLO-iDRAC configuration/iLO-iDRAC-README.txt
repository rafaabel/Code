.DESCRIPTION
These scripts help in automating the iLO/iDRAC configuration

.AUTHOR
Rafael Abel - rafael.abel@effem.com

.DATE
09/16/2021

.HOW TO
You must execute the scripts in the following order:
	- iLO-iDRAC-dnscreation.ps1 (create DNS records)
	- iLO-iDRAC-idssaccountcreation-creating-sitecodeiloidssadmin (create new IDSS local admin accounts [<sitecode> + ilo + idssadmin])
	- iLO-iDRAC-idssaccountdeletion-deleting-idssiloadmin (delete old IDSS local admin accounts [idssiLoAdmin])
	- iLO-iDRAC-certificaterequest.ps1 (request, create and install new certificates)
	- iLO-iDRAC-idssaccountresetpassword-authenticating-with-sitecodeiloidssadmin (set different password for every new IDSS local admin accounts ([<sitecode> + ilo + idssadmin]) 
Optional script 
	- iLO-iDRAC-idssaccountresetpassword-authenticating-with-idssiloadmin.ps1 (set different password for every new IDSS local admin accounts ([<sitecode> + ilo + idssadmin] but authenticatig with idssiLoAdmin local admin account)

REQUIREMENTS:
	- Source file "Mars-AD iLO iDRAC xxxx.xxxx.csv"
	- Source file "Mars-AD iLO iDRAC xxxx.xxxx- RequestID.csv"
	- "password_generation.ps1" script
	