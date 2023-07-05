$driveMappings = @()

# Retrieve all user profiles on the device
$userProfiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -ne $true }

# Loop through each user profile
foreach ($profile in $userProfiles) {
    # Get the username and profile path
    $username = $profile.LocalPath.Split('\')[-1]

    # Determine the user's mapped drives
    $mappedDrives = Get-ChildItem -Path "Registry::HKEY_USERS\$($profile.SID)\Network" -ErrorAction SilentlyContinue |
        ForEach-Object {
            $driveLetter = $_.PSChildName
            $remotePath = Get-ItemPropertyValue -Path "Registry::HKEY_USERS\$($profile.SID)\Network\$($driveLetter)" -Name "RemotePath" -ErrorAction SilentlyContinue

            [PSCustomObject]@{
                Username = $username
                DriveLetter = $driveLetter
                RemotePath = $remotePath
            }
        }

    # Add the user's drive mappings to the array
    $driveMappings += $mappedDrives
}

# Output the drive mappings
$driveMappings | Format-Table -AutoSize