# Run the netsh wlan show interfaces command and store the output in $ssidLines
$ssidLines = (netsh wlan show interfaces)

# Define a regular expression pattern to match the SSID line
$pattern = "^\s*SSID\s*:\s*(.*)$"

# Search for the SSID line using the regular expression pattern
$ssidLine = $ssidLines | Select-String -Pattern $pattern

# Check if an SSID line was found
if ($ssidLine) {
    # Extract the SSID from the matched line
    $ssid = $ssidLine.Matches.Groups[1].Value.Trim()
    Write-Host "SSID: $ssid"

    # Define the netsh command as a string
    $netshCommand = "netsh wlan show profile name='$ssid' key=clear"

    # Use Invoke-Expression to execute the netsh command and store the output in $netshOutput
    $netshOutput = Invoke-Expression $netshCommand

    # Use regex to extract the Key Content
    $keyContent = $netshOutput | Select-String -Pattern "Key Content\s*:\s*(.*)$" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
    
    # Display the Key Content
    Write-Host "Key: $keyContent"
} else {
    Write-Host "SSID not found."
}
Read-Host "Press Enter to exit..."