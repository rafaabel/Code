#::msiexec.exe /i "Quest Change Auditor Agent (x64).msi" /quiet /qn /norestart
"AzureADPasswordProtection"
start-process "msiexec.exe" -arg "/i AzureADPasswordProtectionDCAgentSetup.msi /quiet /qn /norestart" -wait
"Password Change Notification Service"
start-process "msiexec.exe" -arg "/i ""Password Change Notification Service x64\Password Change Notification Service.msi"" /quiet /qn /norestart" -wait
"RMAD Backup Agent"
start-process "msiexec.exe" -arg "/i RMAD\BackupAgent.msi /quiet /qn /norestart /l*!+v install_ba.log" -wait
##New-NetFirewallRule -DisplayName "Quest RMAD" -Direction Inbound -LocalPort 3843 -Protocol TCP -Action Allow
#MAD
##New-NetFirewallRule -DisplayName "Quest RMAD" -Direction Inbound -RemoteAddress 10.200.128.20 -Protocol TCP -Action Allow
#RCAD
##New-NetFirewallRule -DisplayName "Quest RMAD" -Direction Inbound -RemoteAddress 10.200.128.69 -Protocol TCP -Action Allow
#pause
"RMAD Recovery Agent"
.\RMAD\RecoveryAgent64.exe /qn MANAGE_SERVICE=TRUE FRS_FIREWALL_SETTINGS_CONFIGURE=1 /l*!+v install_ra.log
#::.\WindowsSensor.exe /install /passive /norestart CID=EF35878C5A06464CB6B3B7EF692019BE-68
"Upgrade Splunk UF agent to 7.2.0"
start-process "msiexec.exe" -arg "/i splunkforwarder-7.2.0-tran.msi /quiet /qn /norestart /l*!+v install_uf.log" -wait
"Rapid 7 "
start-process "msiexec.exe" -arg "/i Rapid7\agentInstaller-x86_64.msi /quiet /qn /norestart /l*!+v install_r7.log" -wait
"NPCAP"
.\npcap-1.00-oem.exe /S
"Azure ATP Sensor"
Start-Sleep 30
.\"Azure ATP Sensor Setup\Azure ATP Sensor Setup.exe" /quiet NetFrameworkCommandLineArguments="/q" AccessKey="QGetL+CGJGF4AKCfSRMBaA2JHRT0oCXm17C2AOSqIcHtbTooeDMTaO9kkp2lPDrIm8JZQEYLBpKZaG8iVDFCPA=="

"Ready."