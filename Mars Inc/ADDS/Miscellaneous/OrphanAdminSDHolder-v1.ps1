<#
.SYNOPSIS
Detects Orphaned SD Admin users, resets admin count attribute and enables inheritable permissions
 
.Author
Alan.McBurney (+ Ashley Steel)
 
THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
 
Version 1.0, July 10th, 2014
 
.DESCRIPTION
This script gets all users that are members of protected groups within AD and compares
membership with users that have the AD Attribute AdminCount=1 set.
If the user has the AdminCount=1 enabled but is not a member of a protected group then the user
is considered an orphaned admin user and the AdminCount is reset to 0 and inheritable permissions
are reset
 
.REFERENCES
"http://blogs.technet.com/b/heyscriptingguy/archive/2010/07/11/hey-scripting-guy-weekend-scripter-checking-for-module-dependencies-in-windows-powershell.aspx">http://blogs.technet.com/b/heyscriptingguy/archive/2010/07/11/hey-scripting-guy-weekend-scripter-checking-for-module-dependencies-in-windows-powershell.aspx</a>
"http://blogs.msdn.com/b/muaddib/archive/2013/12/30/how-to-modify-security-inheritance-on-active-directory-objects.aspx">http://blogs.msdn.com/b/muaddib/archive/2013/12/30/how-to-modify-security-inheritance-on-active-directory-objects.aspx</a>
 
.EXAMPLE
$orphans = Get-OrphanAdminSdHolderUsers -OutputToPsHost
$orphans | Clear-OrphanAdminSdHolderUser
 
.Notes
To Do list: Enable logging
Originally acquired from here: https://everythingsysadmin.wordpress.com/2014/08/27/fixing-orphaned-adminsdholder-accounts/
#>
 
#Check to Ensure Active Directory PowerShell Module is available within the system
Function Get-MyModule {
    Param([string]$name)
    if (-not(Get-Module -name $name)) {
        if (Get-Module -ListAvailable | Where-Object { $_.name -eq $name }) {
            Import-Module -Name $name
            $True | Out-Null
        }
        else {
            Write-Host ActiveDirectory PowerShell Module Not Available -ForegroundColor Red
        }
    } # end if not module
    else {
        $True | Out-Null
    } #module already loaded
} #end function get-MyModule
 
Get-MyModule -name "ActiveDirectory"
 
Function Set-Inheritance {
    [cmdletbinding()]
    Param($DistinguishedName)

    $Acl = Get-ACL -Path ("AD:\{0}" -f $DistinguishedName)

    If ($Acl.AreAccessRulesProtected -eq $True) {
        $Acl.SetAccessRuleProtection($False, $True)
        Set-ACL -AclObject $ACL -Path ("AD:\{0}" -f $DistinguishedName);
    }
}

Function Get-FlaggedAsAdminGroups {
    Get-ADGroup -LDAPFilter "(adminCount=1)"
}

Function Get-FlaggedAsAdminUsers {
    Get-ADUser -LDAPFilter "(adminCount=1)"
}

Function Get-AdminGroupUsers {
    $RawAdminUsers = ForEach ($Group in Get-FlaggedAsAdminGroups) {
        # Get all users from all admin groups recursively
        Get-ADGroupMember $Group -Recursive | Where-Object { $_.ObjectClass -eq "User" }
        # ...then sort them by distinguishedName to ensure accurate -Unique results (because some users might be in multiple protected groups)
    }
	
    $RawAdminUsers | Sort-Object distinguishedname | Select-Object -Unique;
}

Function Get-OrphanAdminSdHolderUsers {
    [cmdletbinding()]	
    param(
        [switch]$OutputToPsHost
    )
	
    #Get List of Admin Users (Past and Present)
    $UsersFlaggedAsAdmin = Get-FlaggedAsAdminUsers
	
    $UsersInAdminGroups = Get-AdminGroupUsers;
	
    #Compare $AdminUsers to $Admins and place in appropriate hash table
    $OrphanedUsers = ForEach ($User in $UsersFlaggedAsAdmin) {
        If ($UsersInAdminGroups.samAccountName -notcontains $User.samAccountName) {
            if ( $OutputToPsHost.IsPresent ) {
                Write-Host ("ORPHAN`t`t{0}" -f $User.samAccountName);
            }
            $User;
        }
        else {
            if ( $OutputToPsHost.IsPresent ) {
                Write-Host ("STILL ADMIN`t{0}" -f $User.samAccountName);
            }
        }
    }

    return $OrphanedUsers;
}
	
Function Clear-OrphanAdminSdHolderUser {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline)]
        [Microsoft.ActiveDirectory.Management.ADPrincipal[]]$OrphanUser,
        [bool]$Confirm = $true
    )

    Begin {

    }

    Process {
        if ( $OrphanUser.SamAccountName -eq "krbtgt" ) {
            Write-Warning "krbtgt has been skipped; it's unlikely you actually wish to demote this from being a protected user";
        }
        else {
            $Proceed = $false;
            if ( $Confirm ) {
                $Proceed = (Read-Host ("Do you wish to clear adminCount from {0}? Y or anything else" -f $OrphanUser.samAccountName)).toLower() -eq "y";
            }
            else {
                $Proceed = $true;
            }
            if ( $Proceed ) {
                Write-Host ("{0}: Clearing AdminCount..." -f $OrphanUser.SamAccountName) -NoNewline;
                $OrphanUser | Set-ADUser -Clear { AdminCount } -ErrorAction Continue -ErrorVariable ClearError;
                if ( $ClearError.Count -gt 0 ) {
                    Write-Error ("{0} | Set-ADUser -Clear {AdminCount} failed. See error above" -f $OrphanUser.samAccountName);
                    exit;
                }
                else {
                    Write-Host "OK...Enabling Inheritence..." -NoNewline;
                    Set-Inheritance $OrphanUser -ErrorAction Continue -ErrorVariable InheritenceError;
                    if ( $InheritenceError.Count -gt 0) {
                        Write-Error ("Set-Inheritence -DistinguishedName {0} failed. See error above" -f $OrphanUser.distinguishedname);
                        exit;
                    }
                    else {
                        ccc
                        Write-Host "OK";
                    }
                }
            }
            else {
                Write-Host ("{0} skipped" -f $OrphanUser.samAccountName)
            }
        }
    }
}