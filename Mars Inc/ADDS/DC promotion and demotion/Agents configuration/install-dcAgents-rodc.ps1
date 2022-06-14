"Upgrade Splunk UF agent to 7.2.0"
start-process "msiexec.exe" -arg "/i splunkforwarder-7.2.0-tran.msi /quiet /qn /norestart /l*!+v install_uf.log" -wait
"Rapid 7 "
start-process "msiexec.exe" -arg "/i Rapid7\agentInstaller-x86_64.msi /quiet /qn /norestart /l*!+v install_r7.log" -wait
"NPCAP"
.\npcap-1.00-oem.exe /S
"Azure ATP Sensor"
.\"Azure ATP Sensor Setup\Azure ATP Sensor Setup.exe" /quiet NetFrameworkCommandLineArguments="/q" AccessKey="QGetL+CGJGF4AKCfSRMBaA2JHRT0oCXm17C2AOSqIcHtbTooeDMTaO9kkp2lPDrIm8JZQEYLBpKZaG8iVDFCPA=="

"Ready."