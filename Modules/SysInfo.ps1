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
        $basicInfo = Get-ComputerInfo | Select-Object CSName, WindowsVersion, OSArchitecture, WindowsBuildLabEx
        $basicInfo | ForEach-Object {
            $_ | Format-List | Out-String | ForEach-Object {
                Show-Message $_
                Write-Log -logFileName "system_info_log" -message "BasicSystemInfo: $_" -functionName "Get-ComputerInfo"
            }
        }
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "🔥 CPU Information 🔥"
    try {
        # Log and display CPU information
        $cpuInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
        $cpuInfo | ForEach-Object {
            $_ | Format-List | Out-String | ForEach-Object {
                Show-Message $_
                Write-Log -logFileName "system_info_log" -message "CPUInfo: $_" -functionName "Get-CimInstance (CPU)"
            }
        }
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "🌱 Memory Information 🌱"
    try {
        # Log and display Memory information
        $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object Manufacturer, Capacity, Speed, MemoryType
        $memoryInfo | ForEach-Object {
            $_ | Format-List | Out-String | ForEach-Object {
                Show-Message $_
                Write-Log -logFileName "system_info_log" -message "MemoryInfo: $_" -functionName "Get-CimInstance (Memory)"
            }
        }
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "💾 Disk Information 💾"
    try {
        # Log and display Disk information
        $diskInfo = Get-CimInstance -ClassName Win32_DiskDrive | Select-Object DeviceID, Model, Size
        $diskInfo | ForEach-Object {
            $_ | Format-List | Out-String | ForEach-Object {
                Show-Message $_
                Write-Log -logFileName "system_info_log" -message "DiskInfo: $_" -functionName "Get-CimInstance (Disk)"
            }
        }
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "🌐 Network Adapter Information 🌐"
    try {
        # Log and display Network adapter information
        $networkInfo = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object Name, MACAddress, LinkSpeed
        $networkInfo | ForEach-Object {
            $_ | Format-List | Out-String | ForEach-Object {
                Show-Message $_
                Write-Log -logFileName "system_info_log" -message "NetworkInfo: $_" -functionName "Get-NetAdapter (Network)"
            }
        }
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "🖥️ OS Details 🖥️"
    try {
        # Log and display Operating system details
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $osInfo | ForEach-Object {
            $_ | Format-List | Out-String | ForEach-Object {
                Show-Message $_
                Write-Log -logFileName "system_info_log" -message "OSInfo: $_" -functionName "Get-CimInstance (OS)"
            }
        }
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "📜 BIOS Information 📜"
    try {
        # Log and display BIOS information
        $biosInfo = Get-CimInstance -ClassName Win32_BIOS
        $biosInfo | ForEach-Object {
            $_ | Format-List | Out-String | ForEach-Object {
                Show-Message $_
                Write-Log -logFileName "system_info_log" -message "BIOSInfo: $_" -functionName "Get-CimInstance (BIOS)"
            }
        }
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Show-Message "🎨 GPU Information 🎨"
    try {
        # Log and display GPU information
        $gpuInfo = Get-CimInstance -ClassName Win32_VideoController
        $gpuInfo | ForEach-Object {
            $_ | Format-List | Out-String | ForEach-Object {
                Show-Message $_
                Write-Log -logFileName "system_info_log" -message "GPUInfo: $_" -functionName "Get-CimInstance (GPU)"
            }
        }
    }
    catch {
        Write-Error "Error retrieving basic system information: $_"
        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"
    }

    Write-Host "`n"

    Write-Host "✅ Computer Information Collection Completed Successfully! ✅" -ForegroundColor Green -BackgroundColor Black
}