# Invoke-Expression -Command "$(Split-Path $MyInvocation.MyCommand.Path)\install-agent.ps1";

# Invoke-Expression -Command "$(Split-Path $MyInvocation.MyCommand.Path)\sysprep-generalize.ps1";

# creates agent folder on root and change directory into it
mkdir \agent;
cd \agent;
# create variable to target version of agent
$versionNumber = "2.150.3";
$version = "vsts-agent-win-x64-2.150.3.zip";
# downloads agent zipfile
Invoke-WebRequest -Uri "https://vstsagentpackage.azureedge.net/agent/$($versionNumber)/$($version)" -OutFile "C:\agent\$($version)";

Add-Type -AssemblyName System.IO.Compression.FileSystem;
# Extracts agent zipped files
[System.IO.Compression.ZipFile]::ExtractToDirectory("C:\agent\$($version)", "$PWD");

# sysprep & generalize
$sysprep = 'C:\Windows\System32\Sysprep\Sysprep.exe';

$arg = '/generalize /oobe /shutdown /quiet';

Invoke-Command -ScriptBlock {param($sysprep,$arg) Start-Process -FilePath $sysprep -ArgumentList $arg} -ArgumentList $sysprep,$arg;
