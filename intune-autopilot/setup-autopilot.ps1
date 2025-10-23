[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set execution policy for this session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

# Install script/module if not already present
if (-not (Get-Command Get-WindowsAutopilotInfoCommunity -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
    Install-Script -Name get-windowsautopilotinfocommunity -Force
}
if (-not (Get-Module WindowsAutopilotIntuneCommunity -ListAvailable)) {
    Install-Module -Name WindowsAutopilotIntuneCommunity -Force
}

# Connect interactively to Microsoft Graph
# (you may specify scopes if needed)
Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All","Device.ReadWrite.All","Group.ReadWrite.All"

# Now run the Autopilot import

Get-WindowsAutopilotInfoCommunity -Online -Verbose

# Optionally, reboot so Autopilot profile applies
Write-Host "Import complete. Restarting device..."
Restart-Computer -Force -Confirm:$false
