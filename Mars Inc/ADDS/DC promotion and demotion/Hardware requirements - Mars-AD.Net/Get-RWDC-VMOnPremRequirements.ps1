<#
.Synopsis
   Script to check hardware requirements for RODC and RWDC in Mars-AD.Net and RCAD.Net
.DESCRIPTION
   Check hardware requirements according to the pre-defined values
   Technical terms
        RWDC - Read Write Domain Controller
        RODC - Ready Only Domain Controller
        ADDS - Active Directory Domain Services
        DNS - Domain Name System
        OS - Operating System
        VM - Virtual Machine
.REQUIREMENTS
   This script must be run locally from every Windows Server planned to be Domain Controller
.AUTHOR
   Rafael Abel - rafael.abel@effem.com
.DATE
    03/24/2022
#>

#Declare global variables
$drives = Get-CimInstance -Class Win32_LogicalDisk -ComputerName localhost | 
Where-Object { $_. DriveType -eq 3 } | 
Select-Object DeviceID, { $_.Size / 1GB }, { $_.FreeSpace / 1GB }
$memory = Get-CimInstance -class "win32_physicalmemory" -computername localhost | Select-Object { $_.capacity / 1GB }
$totalNumberofMemory = $memory.' $_.capacity / 1GB ' | ForEach-Object -begin { $sum = 0 } -process { $sum += $_ } -end { $sum }
$CPUs = Get-CimInstance -Class Win32_Processor -ComputerName localhost |
Select-Object DeviceID, Description, NumberOfCores, NumberOfLogicalProcessors
$totalNumberofCPUCores = $CPUs.NumberOfCores | ForEach-Object -begin { $sum = 0 } -process { $sum += $_ } -end { $sum }
$totalNumberOfCPULogicalProcessors = $CPUs.NumberOfCores | ForEach-Object -begin { $sum = 0 } -process { $sum += $_ } -end { $sum }

#Set up pre-defined requirements values
$C = 139.000000000000
$D = 59.000000000000
$E = 49.000000000000
$F = 79.000000000000
$memorysize = 24.000000000
$cpucores = 8
$cpulogicalprocessors = 16

ForEach ($drive in $($drives)) {
    #Check if drive is C and and if its value matches with the drive size requirements:
    If ($drive.DeviceID -eq "C:") {
        If (($($drive. { $_.Size / 1GB }) -ge $C)) {
            Write-Host "Current $($drive.DeviceID) size is $($drive. { $_.Size / 1GB }) GB - [Passed]" -ForegroundColor Green
        }
        Else {
            Write-Host "Current $($drive.DeviceID) size is $($drive. { $_.Size / 1GB }) GB - [Failed]" -ForegroundColor Red
        }
    }
    #Check if drive is D and if its value matches with the drive size requirements:
    Elseif ($drive.DeviceID -eq "D:") {
        If (($($drive. { $_.Size / 1GB }) -ge $D)) {
            Write-Host "Current $($drive.DeviceID) size is $($drive. { $_.Size / 1GB }) GB - [Passed]" -ForegroundColor Green
        }
        Else {
            Write-Host "Current $($drive.DeviceID) size is $($drive. { $_.Size / 1GB }) GB - [Failed]" -ForegroundColor Red
        }
    }

    #Check if drive is E and if its value matches with the drive size requirements:
    ElseIf ($drive.DeviceID -eq "E:") {
        If (($($drive. { $_.Size / 1GB }) -ge $E)) {
            Write-Host "Current $($drive.DeviceID) size is $($drive. { $_.Size / 1GB }) GB - [Passed]" -ForegroundColor Green
        }
        Else {
            Write-Host "Current $($drive.DeviceID) size is $($drive. { $_.Size / 1GB }) GB - [Failed]" -ForegroundColor Red
        }
    }

    #Check if drive is F and if its value matches with the drive size requirements:
    ElseIf ($drives.DeviceID -eq "F:") {
        If (($($drive. { $_.Size / 1GB }) -ge $F)) {
            Write-Host "Current $($drive.DeviceID) size is $($drive. { $_.Size / 1GB }) GB - [Passed]" -ForegroundColor Green
        }
        Else {
            Write-Host "Current $($drive.DeviceID) size is $($drive. { $_.Size / 1GB }) GB - [Failed]" -ForegroundColor Red
        }
    }
    Else {
        Write-Host "No more drives to be checked" -ForegroundColor Red
    }
}

#Check if the memory value matches with the memory size requirements:
If ($totalNumberofMemory -ge $memorysize) {
    Write-Host "Current memory size is $totalNumberofMemory GB - [Passed]" -ForegroundColor Green
}
Else {
    Write-Host "Current memory size is $totalNumberofMemory GB - [Failed]" -ForegroundColor Red
}
    
#Check if the CPU model description matches with the requirements:
If ($CPUs.Description -like "Intel64 Family*") {
    Write-Host "CPU is $($CPUs.Description) - [Passed]" -ForegroundColor Green
}
Else {
    Write-Host "CPU is $($CPUs.Description) - [Failed]" -ForegroundColor Red
}

#Check if the CPU cores matches with the requirements:
If ($totalNumberofCPUCores -ge $cpucores) {
    Write-Host "Total current number of CPU cores is $totalNumberofCPUCores - [Passed]" -ForegroundColor Green
}
Else {
    Write-Host "Total current number of CPU cores is $totalNumberofCPUCores - [Failed]" -ForegroundColor Red
}

#Check if the CPU logical processors matches with the requirements:
If ($totalNumberOfCPULogicalProcessors -ge $cpulogicalprocessors) {
    Write-Host "Total current number of CPU logical processors is $totalNumberOfCPULogicalProcessors - [Passed]" -ForegroundColor Green
}
Else {
    Write-Host "Total current number of CPU logical processors is $totalNumberOfCPULogicalProcessors - [Failed]" -ForegroundColor Red
}

