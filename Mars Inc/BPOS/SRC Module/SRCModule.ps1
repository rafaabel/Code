<#
.SYNOPSIS
  Common Scripts to assist the SRC Team in requests fulfillment.
.DESCRIPTION
  This script contains some scripts to assist the SRC Team in request fulfillment, like
  Shared Mailbox Creation, Royal Canin Shared Folder Creation, Meeting Room Creation and Meeting Room Edition
.INPUTS
  SNow Requests inputs
.OUTPUTS
  Shared Mailbox, Access Groups and Resources created on Active Directory
.NOTES
  Version:        1.0
  Author:         Junior, Marcos
  Creation Date:  August 09, 2018
  Purpose: Initial script development
#>

	#Connecting to ARS Service if the connection is null
	if(!$QADConnection) {
		Connect-QADService -proxy vmww4618.mars-ad.net -Credential $cred
	}

    #Connecting to Exchange Online if the connection is null
    if(!$PSSession) {
        Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)

        $EXOSession = New-ExoPSSession

        Import-PSSession $EXOSession
    }


Function Edit-MeetingRoom {


Param(
	[Parameter(
		Mandatory=$true, 
		HelpMessage="Inform the E-mail Adress or the Display Name from the Target Room")
	]
    [String]
    $Room,
    [Parameter(
    	HelpMessage="Inform the new Display Name if you're going to change the room's name")]
    [String]
    $NewDisplayName,
    [Parameter (
    	HelpMessage="Inform the Phone Number if you're going to change or add the room's phone number")]
    [String]
    $Phone,
    [Parameter(
    	HelpMessage="Inform the Room's resources separated by comma. For example: 'SPKPHON','TV','PLASMA'")]
    [System.Collections.ArrayList]
    $Resources,
    [Parameter (
    	HelpMessage="Inform the Room's Capacity")]
    [Int32]
    $Capacity,
    [String]
    $Location,
    [Parameter (
    	HelpMessage="Additional information about the room. For example: 'Site Administrator: Junior, Marcos'")]
    [String]
    $Info
    );


	$target = Get-QADUser -Identity $room

	if($NewDisplayName) {
        Write-Host  "Meeting Room Edition - Setting a new Display Name"
		$target | Set-QADUser -DisplayName $NewDisplayName
	}

	if($Phone) {
        Write-Host  "Meeting Room Edition - Setting a new Phone Number"
		$target | Set-QADUser -PhoneNumber $Phone
	}

	if($Resources) {
        Write-Host  "Meeting Room Edition - Setting a new Resource Display"
		Set-Mailbox -Identity $room -ResourceCustom $Resources
	}

	if($Capacity) {
        Write-Host  "Meeting Room Edition - Setting a new Capacity"
		Set-Mailbox -Identity $room -ResourceCapacity $Capacity
	}

    if($Location) {
        Write-Host "Meeting Room Edition - Setting a new location"
        $target | Set-QADUser -Office $Location
    }

	if($Info) {
        Write-Host  "Meeting Room Edition - Setting a new Room Info"
		$target | Set-QADUser -Info $Info
	}

    $target | Set-QADUser -ObjectAttributes @{extensionAttribute12 = 'Update'}

    Write-Host "Meeting Room $($target.Name) has been modified successfully!" -ForegroundColor Green;

}

function Create-RCSharedFolder {

<# 
    .DESCRIPTION

        ATENTION: To run this script, you need to run the Powershell with your RCAD credentials
        This function creates a new Royal Canin Shared Folder and its Access Group
        The inputs are the Site, Folder Name, Owner, Read&Write members (semicolon separated), ReadOnly members (semicolon separated) and wheter the folder is Replicated (Deptshare) or Not Replicate (Apps).        
        
    .EXAMPLE
        Create-RCSharedFolder -Name "RCD_Template_files"`
                             -Site "RCD"`
                             -Owner "juniomar"`
                             -RWMembers "juniomar;admjuniomar;admsantoan5"`
                             -ROMembers "admabelraf"`
                             -IsReplicated $true
#>

Param (
    [String]$site,
    [String]$name,
    [String]$owner,
    [String]$RWMembers,
    [String]$ROMembers,
    [ValidateSet($true,$false)]
    [bool]$IsReplicated
);


#BEGIN - SNOW INPUTS

    #Folder Site location
    $site;
    #Folder Name
    $name;
    #Folder Owner
    $owner;
    #RW Members (Semicolon separated)
    $RWMembers;
    #RO Members (Semicolon separated)
    $ROMembers;
    #IsReplicated 
    $IsReplicated;
        
#END - SNOW INPUTS

if($IsReplicated)
{
    $Path = "\\rcad.net\dfs\$site\deptshare\";
    $isRep = "R";
}
else
{
    $Path = "\\rcad.net\dfs\$site\apps\";
    $isRep = "S";
}

#CREATING THE ACCESS GROUPS
#READ ONLY

$DomainGroup = $site + "DLACLS" + $isRep + "R-$name";
$GlobalGroup = $site + "GLACLS" + $isRep + "R-$name";

try{
 
New-QADGroup -Name $DomainGroup -DisplayName $DomainGroup -SamAccountName $DomainGroup -GroupScope "DomainLocal" -GroupType "Security"`
             -ParentContainer $(Get-QADObject -SearchRoot 'DC=RCAD,DC=NET' -Type OrganizationalUnit * | ? {$_.DN -match "OU=$site,OU=Groups*"} | Select DN -ExpandProperty DN)`

New-QADGroup -Name $GlobalGroup -DisplayName $GlobalGroup -SamAccountName $GlobalGroup -GroupScope "Global" -GroupType "Security"`
             -ParentContainer $(Get-QADObject -SearchRoot 'DC=RCAD,DC=NET' -Type OrganizationalUnit * | ? {$_.DN -match "OU=$site,OU=Groups*"} | Select DN -ExpandProperty DN)`
             -ManagedBy (Get-QADUser $owner -SearchRoot "DC=RCAD,DC=NET").DN

} catch {
    $Error
}

try {
Add-QADGroupMember -Identity $DomainGroup -Member $GlobalGroup -Verbose
} catch {
    $Error
}

#Adding the RO members
foreach($user in $ROMembers.Split(';'))
{
    Try {
    Add-QADGroupMember -Identity $GlobalGroup -Member (Get-QADUser $user -SearchRoot "DC=RCAD,DC=NET").DN -Verbose -ErrorAction Continue
    } catch {
    $Error
    }
}

$readGroup = $DomainGroup;

$DomainGroup = $site + "DLACLS" + $isRep + "W-$name";
$GlobalGroup = $site + "GLACLS" + "$isRep" + "W-$name";

try {
 
New-QADGroup -Name $DomainGroup -DisplayName $DomainGroup -SamAccountName $DomainGroup -GroupScope "DomainLocal" -GroupType "Security"`
             -ParentContainer $(Get-QADObject -SearchRoot 'DC=RCAD,DC=NET' -Type OrganizationalUnit * | ? {$_.DN -match "OU=$site,OU=Groups*"} | Select DN -ExpandProperty DN)`

New-QADGroup -Name $GlobalGroup -DisplayName $GlobalGroup -SamAccountName $GlobalGroup -GroupScope "Global" -GroupType "Security"`
             -ParentContainer $(Get-QADObject -SearchRoot 'DC=RCAD,DC=NET' -Type OrganizationalUnit * | ? {$_.DN -match "OU=$site,OU=Groups*"} |  Select DN -ExpandProperty DN)`
             -ManagedBy (Get-QADUser $owner -SearchRoot "DC=RCAD,DC=NET").DN

} catch {
    $Error
}

try {
Add-QADGroupMember -Identity $DomainGroup -Member $GlobalGroup -Verbose
} catch {
    $Error
}

#Adding the RW Members
foreach($user in $RWMembers.Split(';'))
{
    try {
    Add-QADGroupMember -Identity $GlobalGroup -Member (Get-QADUser $user -SearchRoot "DC=RCAD,DC=NET").DN -Verbose -ErrorAction Continue
    } catch {
    $Error
    }
}

$writeGroup = $DomainGroup;



try {
    #Creating the folder
    New-Item -ItemType Directory -Path "$Path\$name" -ErrorAction Stop

    #Setting the folder permissions
    $ACL = Get-Acl -Path "$Path\$name" -ErrorAction Stop;
    $ReadOnly = New-Object System.Security.AccessControl.FileSystemAccessRule ("RCAD\$readGroup","ReadAndExecute","ObjectInherit","InheritOnly","Allow");
    $ReadWrite = New-Object System.Security.AccessControl.FileSystemAccessRule ("RCAD\$writeGroup","Modify","ObjectInherit","InheritOnly","Allow");
    $ACL.AddAccessRule($ReadOnly);
    $ACL.AddAccessRule($ReadWrite);
    Set-Acl -Path "$Path\$name" -AclObject $ACL -ErrorAction Stop
    Get-Acl -Path "$path\$name"
    Write-Host "Your shared folder $Path\$name has been created successfully"
} catch {
    $Error
}

}

function Create-SharedMailbox {

<# 
    .DESCRIPTION
        This function creates a new Shared Mailbox and its Access Group
        The inputs are the Display Name, E-mail Address, Division (Mars, Royal Canin or Wrigley), Members list (separated by semicolon), Owner and ExternalAccess enabled (Y or N).
        After the Shared Mailbox and Access Group replication, please run the following command using the Exchange Powershell Module:

            Add-MailboxPermission -Identity $Mailbox -User $AccessGroup -AccessRights FullAccess
            Set-Mailbox -Identity $Mailbox -GrantSendOnBehalfTo $AccessGroup

    .EXAMPLE
        Create-SharedMailbox -DisplayName "Automation Shared Mailbox"` 
                             -EmailAddress "automationsmb@effem.com"`
                             -Division Mars `
                             -MembersList "marcos.junior@effem.com;andre.santos@effem.com;eduardo.filho@effem.com"` 
                             -Owner "marcos.junior@effem.com"` 
                             -ExternalAccess N
#>


    param(
        [String]$DisplayName,
        [String]$EmailAddress,
        [ValidateSet('Mars','Royal Canin','Wrigley')]
        [String]$Division,
        [String]$MembersList,
        [String]$Owner,
        [ValidateSet('Y','N')]
        [String]$ExternalAccess
    );

Write-host "================== Shared Mailbox Creation =================="

#Function to Convert the Object GUID to MarsIdmUid
function Convert-GuidToOctetString {
    param
    (
        [String]$Guid
    );
    [Guid]$g = New-Object Guid;
    if([Guid]::TryParse($Guid, [ref]$g)) {
        return ([System.String]::Join('', ($g.ToByteArray() | ForEach-Object { $_.ToString('x2') })).ToUpper());
    }
}


    #Local Variables
        $ParentContainer = "OU=Shared Mailboxes,OU=$division,OU=Exchange,OU=IT-Services,DC=Mars-AD,DC=Net";
        $MailNickname = $EmailAddress.Split('@')[0] -replace '[\W]',''
        if($MailNickname.Length -gt 20) {
            $MailNickname = $MailNickname.Substring(0,20)
        }

    #Start Shared Mailbox Creation

        Write-Host "===== Creating the Shared Mailbox - $DisplayName ====="

        try {
            New-QADUser -Name $MailNickname `
                        -DisplayName $DisplayName `
                        -SamAccountName $MailNickname `
                        -UserPrincipalName $EmailAddress `
                        -mail $EmailAddress `
                        -ParentContainer $ParentContainer `
                        -ObjectAttributes @{
                            targetaddress = "smtp:"+$MailNickname+"@mars.onmicrosoft.com"; 
                            mailNickname  = $MailNickname; 
                            extensionAttribute8 = "REG=NA;TYPE=SHARED;MBX=10GB;"; 
                            extensionAttribute10 = $ExternalAccess; 
                            extensionAttribute11 = "HASMBX"; 
                            extensionAttribute12 = "New"; 
                            ProxyAddresses = @("smtp:$($MailNickname+"@mars.onmicrosoft.com")","SMTP:$EmailAddress");
                            } `
                        -ErrorAction Stop

            $CurrentUser = Get-QADUser $MailNickname
    
            Set-QADUser $CurrentUser -ObjectAttributes @{marsIdmUid = Convert-GuidToOctetString($CurrentUser.objectguid); mailNickname = $MailNickname}

            Disable-QADUser $CurrentUser
        }
        catch {
            Write-Information "Error to perform this action, please check the log in C:\Temp\SRCScript.log"
            Add-Content -Path "C:\Temp\SRCScript.log" -Value $Error
            if ($error[0].Exception -like ("*already in use*")) {
                Write-Error "The Shared Mailbox $DisplayName already exists! Please check on AD and then check your template file." 
              
            }
        }

        #Start Access Group creation

        Write-Host "===== Creating the Access group for - $DisplayName ====="

        try {
            New-QADGroup -Name "SMB_Access_$MailNickname"`
                         -DisplayName "SMB_Access_$MailNickname"`
                         -SamAccountName "SMB_Access_$MailNickname"`
                         -GroupScope Universal `
                         -GroupType Security `
                         -ParentContainer "OU=Shared Mailboxes Access,OU=Security Groups,OU=$Division,OU=Exchange,OU=IT-Services,DC=Mars-AD,DC=Net"`
                         -ObjectAttributes @{
                            targetaddress = "smtp: SMB_Access_"+$MailNickname+"@mars.onmicrosoft.com";
                            ProxyAddresses = "smtp: SMB_Access_"+$MailNickname+"@mars.onmicrosoft.com";
                            mail = "SMB_Access_"+$EmailAddress;
                            mailNickname = "SMB_Access_"+$MailNickname;
                            marsAzureAdSyncAllow = "Y";
                            } `
                         -ManagedBy $(Get-QADUser $Owner -SearchRoot "DC=Mars-AD,DC=Net")

                         #Check the members specified on Members column and then add them to the access group
                         foreach ($Member in $MembersList.Split(';')) {
                            Write-Host "===== Adding $Member to the Access group for - $DisplayName ====="
                            try {
                                Add-QADGroupMember -Identity "SMB_Access_$MailNickname" -Member $(Get-QADUser $Member -SearchRoot "DC=Mars-AD,DC=Net") -ErrorAction Continue     
                            }
                            catch {
                                Add-Content -Path "C:\Temp\SRCScript.log" -Value $Error
                                Write-Warning $error[0].Exception
                            }
                         }   
        }
        catch {
            Write-Information "Error to perform this action, please check the log in C:\Temp\SRCScript.log"
            Add-Content -Path "C:\Temp\SRCScript.log" -Value $Error
            if ($error[0].Exception -like ("*already in use*")) {
                Write-Error "The Access group for $DisplayName Already exists! Please check on AD and then check your template file"   
            }
        }   
        
        if(($(Get-QADUser -Identity $EmailAddress) -ne $null) -and ($(Get-QADGroup -Identity "smb_access_$MailNickname"))){
        Write-Host "The Shared Mailbox '$EmailAddress' and the accessgroup 'smb_access_$MailNickname@mars.onmicrosoft.com' has been created successfully!" -ForegroundColor Green;
        }
}

Function EnableSkypeRoom {

Param (
    [Parameter(Mandatory=$true)]
    [String]
    $Room
);

$target = Get-QADUser -Identity $Room;

$emailAddress = $target.mail

$target | Set-QADUser -objectAttributes @{extensionAttribute5 = 127; extensionAttribute12 = "Update"; edsaUPNPrefix = $emailAddress.split('@')[0]; edsaUPNSuffix = $emailAddress.split('@')[1] }

Add-QADGroupMember -Identity "SRS Accounts" -Member $target

Move-QADObject $target -NewParentContainer "OU=SRS,OU=Resources,OU=Mars,OU=Exchange,OU=IT-Services,DC=Mars-AD,DC=Net"

Set-QADUser -Identity $Room -UserPassword "Polycom!LVC"

}

function Create-MeetingRoom {

    param(
        [String]$DisplayName,
        [String]$EmailAddress,
        [ValidateSet('Mars','Royal Canin','Wrigley')]
        [String]$Division,
        [String]$Site,
        [String]$Phone,
        [System.Collections.ArrayList]$Resources,
        [Int32]$Capacity,
        [String]$Location,
        [Parameter (
    	    HelpMessage="Additional information about the room. For example: 'Site Administrator: Junior, Marcos'")]
        [String]$Info,
        [ValidateSet('Standard', 'Restricted')]
        [String]$Type,
        [String]$MembersList
    );

Write-host "================== Meeting Room Creation =================="

#Function to Convert the Object GUID to MarsIdmUid
function Convert-GuidToOctetString {
    param
    (
        [String]$Guid
    );
    [Guid]$g = New-Object Guid;
    if([Guid]::TryParse($Guid, [ref]$g)) {
        return ([System.String]::Join('', ($g.ToByteArray() | ForEach-Object { $_.ToString('x2') })).ToUpper());
    }
}


    #Local Variables
        $ParentContainer = "OU=Resources,OU=$Division,OU=Exchange,OU=IT-Services,DC=Mars-AD,DC=Net" ;
        if($Division.toLower() -eq "wrigley") { $ParentContainer = "OU=Resources,OU=Wrigley,OU=Exchange,OU=IT-Services,DC=Mars-AD,DC=Net"}
        $MailNickname = $EmailAddress.Split('@')[0] -replace '[\W]',''
        if($MailNickname.Length -gt 20) {
            $MailNickname = $MailNickname.Substring(0,20)
        }

    #Start Meeting Creation

        Write-Host "===== Creating the Meeting Room - $DisplayName ====="

        try {
            New-QADUser -Name $DisplayName `
                        -DisplayName $DisplayName `
                        -SamAccountName $MailNickname `
                        -UserPrincipalName $EmailAddress `
                        -mail $EmailAddress `
                        -ParentContainer $ParentContainer `
                        -ObjectAttributes @{
                            targetaddress = "smtp:"+$MailNickname+"@mars.onmicrosoft.com"; 
                            mailNickname  = $MailNickname; 
                            extensionAttribute8 = "REG=NA;TYPE=RESOURCE;RESMBX=roomrba;MBX=5GB;"; 
                            extensionAttribute11 = "HASMBX"; 
                            extensionAttribute12 = "New"; 
                            ProxyAddresses = @("smtp:$($MailNickname+"@mars.onmicrosoft.com")","SMTP:$EmailAddress");
                            } `
                        -ErrorAction Stop

            $CurrentUser = Get-QADUser $MailNickname
    
            Set-QADUser $CurrentUser -ObjectAttributes @{marsIdmUid = Convert-GuidToOctetString($CurrentUser.objectguid); mailNickname = $MailNickname}

            if($SkypeEnabled) {
            Set-QADUser $CurrentUser -ObjectAttributes @{extensionAttribute12 = "Update"; extensionAttribute5 = 127; extensionAttribute6 = "UL=US|Conf=2|"}
            }

        }
        catch {
            if ($error[0].Exception -like ("*already in use*")) {
                Write-Error "The Meeting Room $DisplayName already exists! Please check on and then check your query." 
              
            }
        }

        #Start Access Group creation
        if($Type.ToLower() -eq "restricted") {

        Write-Host "===== Creating the Access group for - $DisplayName ====="

        try {
            New-QADGroup -Name "$($MailNickname)_access"`
                         -DisplayName "$($MailNickname)_access"`
                         -SamAccountName "$($MailNickname)_access"`
                         -GroupScope Universal `
                         -GroupType Security `
                         -ParentContainer "OU=Security Groups,OU=$Division,OU=Exchange,OU=IT-Services,DC=Mars-AD,DC=Net"`
                         -ObjectAttributes @{
                            targetaddress = "smtp: $($MailNickname)_access@mars.onmicrosoft.com";
                            ProxyAddresses = "smtp: $($MailNickname)_access@mars.onmicrosoft.com";
                            mail = "$($MailNickname)_access@effem.com";
                            mailNickname = "$($MailNickname)_access";
                            marsAzureAdSyncAllow = "Y";
                            } `

                         #Check the members specified on Members column and then add them to the access group
                         foreach ($Member in $MembersList.Split(';')) {
                            Write-Host "===== Adding $Member to the Access group for - $DisplayName ====="
                            try {
                                Add-QADGroupMember -Identity "$($MailNickname)_access" -Member $(Get-QADUser $Member -SearchRoot "DC=Mars-AD,DC=Net") -ErrorAction Continue     
                            }
                            catch {
                                Write-Warning $error[0].Exception
                            }
                         }   
        }
        catch {
            if ($error[0].Exception -like ("*already in use*")) {
                Write-Error "The Access group for $DisplayName Already exists! Please check on AD and then check your query"   
            }
        }  

        if(($(Get-QADUser -Identity $EmailAddress) -ne $null) -and ($(Get-QADGroup -Identity "smb_access_$MailNickname"))){
        Write-Host "The Restricted Meeting Room '$EmailAddress' and the accessgroup '$($MailNickname)_access' has been created successfully!" -ForegroundColor Green;
        }
        
        } 
        
        if($(Get-QADUser -Identity $EmailAddress) -ne $null){
        Write-Host "The Meeting Room '$EmailAddress' has been created successfully!" -ForegroundColor Green;
        }
}