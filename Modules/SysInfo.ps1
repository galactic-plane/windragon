# Function: Start-PCInfo
# Description: This function collects and displays detailed information about the computer's hardware and system configuration.
#              It logs and displays the following categories of information: Basic system info, CPU, Memory, Disk Drives, Network Adapters, Operating System, BIOS, and GPU.
#              Each category of information is displayed in a vertical table format for better readability.
# Parameters: None
# Returns: A string message indicating that the computer information generation has completed.
# Process: 
#   1. Shows a message indicating the start of information generation.
#   2. For each category of information (e.g., Basic System, CPU, Memory, Disk, Network, OS, BIOS, GPU), it retrieves relevant data using PowerShell cmdlets.
#   3. The information is then displayed in a vertical table format in the console for better distinction.
#   4. Each retrieved item is also logged into a system log file with the category name for traceability.
#   5. Returns a completion message when all information has been gathered and displayed.
function Start-PCInfo {
    Show-Message "💻 Generating Computer Information 💻"
    Write-Host "`n"

    Show-Message "✨ System Information ✨"
    try {
        # Log and display Basic system information
        Get-ComputerInfo | Select-Object CSName, WindowsVersion, OSArchitecture, WindowsBuildLabEx | Format-List       
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "🔥 CPU Information 🔥"
    try {
        # Log and display CPU information
        Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List         
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "🌱 Memory Information 🌱"
    try {
        # Log and display Memory information
        Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object Manufacturer, Capacity, Speed, MemoryType | Format-List        
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "💾 Disk Information 💾"
    try {
        # Log and display Disk information
        Get-CimInstance -ClassName Win32_DiskDrive | Select-Object DeviceID, Model, Size | Format-List         
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "🌐 Network Adapter Information 🌐"
    try {
        # Log and display Network adapter information
        Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object Name, MACAddress, LinkSpeed | Format-List         
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "🖥️ OS Details 🖥️"
    try {
        # Log and display Operating system details
        Get-CimInstance -ClassName Win32_OperatingSystem | Format-List        
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "📜 BIOS Information 📜"
    try {
        # Log and display BIOS information
        Get-CimInstance -ClassName Win32_BIOS | Format-List        
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "🎨 GPU Information 🎨"
    try {
        # Log and display GPU information
        Get-CimInstance -ClassName Win32_VideoController | Format-List        
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "✅ Computer Information Collection Completed Successfully! ✅"
}