# Define your IP range, target MAC vendor, and email settings
# IP range to scan
$ipRangeStart = "192.168.10.1"
$ipRangeEnd = "192.168.10.254"
# MAC address vendor to target
$targetVendor = "*changeme*"
# SMTP settings for email
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$enableSsl = $true
$enableTls = $true
$fromEmail = ""
$toEmail = ""
$subject = "MAC Vendor Match Found"
$emailUsername = ""
$emailPassword = ""
# Rate limit in seconds - how often to check MAC addresses
$rateLimit = 1
# List to store results
$resultsList = @()

# Function to lookup MAC vendor - uses an API to get vendor information from a given MAC address
function Get-MACVendor($mac) {
    $url = "https://api.macvendors.com/$mac"
    try {
        Write-Host "Looking up MAC vendor for $mac"
        $vendor = Invoke-WebRequest -Uri $url -UseBasicParsing
        Write-Host "API Response: $($vendor.Content)"  # Print API response to console
        return $vendor.Content
    } catch {
        return $null
    }
}

# Function to send an email - uses SMTP settings defined above
function Send-Email($body) {
    Write-Host "Sending email: $body"
    $mailMessage = @{
        To = $toEmail
        From = $fromEmail
        Subject = $subject
        Body = $body
        SmtpServer = $smtpServer
        Port = $smtpPort  # Specify the SMTP port
    }

    $mailCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $emailUsername, $($emailPassword | ConvertTo-SecureString -AsPlainText -Force)

    if ($enableSsl) {
        $mailMessage.Add("UseSsl", $true)
    }

    # Enable TLS if specified
    if ($enableTls) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    Send-MailMessage @mailMessage -Credential $mailCredentials
}

# Split IP range into 4 octets and convert to integers
$ipStart = $ipRangeStart.Split(".") | ForEach-Object {[int]$_}
$ipEnd = $ipRangeEnd.Split(".") | ForEach-Object {[int]$_}

# Loop through each IP in the range
for ($octet4 = $ipStart[3]; $octet4 -le $ipEnd[3]; $octet4++){
    # Create the IP address string by joining the octets
    $ip = "$($ipStart[0]).$($ipStart[1]).$($ipStart[2]).$octet4"

    Write-Host "Scanning IP: $ip"
    # Ping the IP address to check if it's active
    $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet
    if ($ping) {
        # If the IP is active, get the MAC address using the arp command
        $arp = arp -a $ip | Select-String -Pattern "(([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2}))" -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value }
        if ($arp) {
            # If the MAC address is found, format it and look up the vendor
            $mac = $arp.Replace("-", ":").ToUpper()
            Write-Host "MAC address found for ${ip}: $mac"
            $vendor = Get-MACVendor -mac $mac
            if ($vendor -like $targetVendor) { 
                # If the vendor matches the target, add a result to the list
                $resultsList += "A device with IP address '${ip}' and MAC address '$mac' matches the target MAC vendor: '$targetVendor'."
            }
        } else {
            Write-Host "No MAC address found for $ip"
        }
    } else {
        Write-Host "No response from IP $ip"
    }
    
    # Rate limit the checks - wait for a specified amount of time before moving on to the next IP
    Start-Sleep -Seconds $rateLimit
}

# If there are any results, send an email with all the results
if ($resultsList.Count -gt 0) {
    # Join the results into a single string, with each result on a new line
    $body = $resultsList -join "`n"
    # Send an email with the results
    Send-Email -body $body
}
