# Initializes the settings by creating a settings file with default values if it doesn't exist.
# Returns the settings read from the settings file.
function Initialize-Settings {
    # Create a settings file for default paths
    $settingsFilePath = "settings.json"

    # Check if settings file exists, if not, create it with default values
    if (-not (Test-Path $settingsFilePath)) {
        $defaultSettings = @{
            defaultSource      = "D:\\"
            defaultDestination = "B:\\"
        }
        ($defaultSettings | ConvertTo-Json -Depth 3) | Set-Content -Path $settingsFilePath
        Write-Host "Settings file created at $settingsFilePath with default values."
    }

    # Read settings from the settings file
    $settings = Get-Content -Path $settingsFilePath | ConvertFrom-Json
    return $settings
}

# Handles errors by throwing an exception if the task name is null or empty.
# Parameters:
#   [string]$taskName - The name of the task.
#   [string]$errorMessage - The error message to display.
function Catcher {
    param (
        [string]$taskName,
        [string]$errorMessage
    )
    
    if ([string]::IsNullOrWhiteSpace($taskName)) {
        throw "Task name cannot be null or empty."
    }
    
    if ([string]::IsNullOrWhiteSpace($errorMessage)) {
        throw "Error message cannot be null or empty."
    }
    
    $global:ErrorRecords += [PSCustomObject]@{
        Task  = $taskName
        Error = $errorMessage
    }
    Write-Log -logFileName 'error_log.txt' -message "Error in task: $taskName - $errorMessage" -functionName $taskName
}

# Function to log messages to a log file in a dated folder
#
# Function: Write-Log
# Description: This function logs messages to a specified log file located in a dated folder.
#              If the folder for today's date does not exist, it creates one. Each log entry is timestamped and formatted as CSV.
# Parameters:
#   [string]$logFileName - The name of the log file where the message will be written.
#   [string]$message - The message to be logged.
#   [string]$functionName - The name of the function calling Write-Log.
# Usage:
#   Write-Log -logFileName "repair_log.txt" -message "Repair task started successfully." -functionName "Start-Repair"
function Write-Log {
    param (
        [string]$logFileName,
        [string]$message,
        [string]$functionName
    )
    
    $date = (Get-Date).ToString('yyyy-MM-dd')
    $logDirectory = "logs"
    if (-not (Test-Path -Path $logDirectory)) {
        try {
            New-Item -ItemType Directory -Path $logDirectory -ErrorAction Stop | Out-Null
        }
        catch [System.UnauthorizedAccessException] {
            Catcher -taskName "Write-Log" -errorMessage $_.Exception.Message
            Show-Error "Failed to create log directory '$logDirectory' due to insufficient permissions. Please check permissions."
            return
        }
        catch [System.IO.IOException] {
            Catcher -taskName "Write-Log" -errorMessage $_.Exception.Message
            Show-Error "Failed to create log directory '$logDirectory' due to an I/O error. Please verify the path and ensure there are no conflicts."
            return
        }
        catch {
            Catcher -taskName "Write-Log" -errorMessage $_.Exception.Message
            Show-Error "Failed to create log directory '$logDirectory' due to an unexpected error: $_.Exception.Message"
            return
        }
    }
    
    $logFilePath = "$logDirectory\$logFileName-$date.csv"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Check if the log file exists, if not add headers
    if (-not (Test-Path -Path $logFilePath)) {
        Add-Content -Path $logFilePath -Value "Timestamp,FunctionName,Message"
    }
    
    # Prepare the log message in CSV format
    $logMessage = "$timestamp,$functionName,$message"
    
    # Use a file lock to prevent data corruption when multiple processes write to the same log file
    $fileStream = [System.IO.File]::Open($logFilePath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $writer = New-Object System.IO.StreamWriter($fileStream)
        $writer.BaseStream.Seek(0, [System.IO.SeekOrigin]::End)
        $writer.WriteLine($logMessage)
        $writer.Flush()
    }
    finally {
        $writer.Close()
        $fileStream.Close()
    }
}

# Function to run a virus scan using Windows Defender based on the current status
#
# Function: Start-DefenderScan
# Description: This function checks the status of Windows Defender and initiates either a quick scan or a full scan 
#              based on whether a scan is overdue. If QuickScanOverdue is true, it starts a quick scan. If FullScanOverdue
#              is true, it starts a full scan.
# Parameters:
#   None
# Usage:
#   Start-DefenderScan
function Start-DefenderScan {    
    param (
        [switch]$Force
    )

    # Check if Windows Defender is the default antivirus provider
    $defaultAV = Get-MpPreference
    if ($null -eq $defaultAV) {
        Write-Host "Windows Defender is not the default virus scanner. Exiting function."
        return
    }

    # Check if the quick scan has run at least once
    if (-not $global:QuickScanRunOnce -or $Force) {
        Write-Host "Starting Windows Defender Quick Scan..." -ForegroundColor Green
        # Command to start the quick scan
        Start-MpScan -ScanType QuickScan

        # Set the flag to true after the first run
        $global:QuickScanRunOnce = $true
    }
    else {
        # Get the current status of the computer's Defender settings
        $computerStatus = Get-MpComputerStatus

        # Check if a quick scan is overdue and run the appropriate scan
        if ($computerStatus.QuickScanOverdue -eq $true) {
            Write-Host "Quick scan is overdue. Starting a quick virus scan with Windows Defender..."
            Start-MpScan -ScanType QuickScan
        }
        elseif ($computerStatus.FullScanOverdue -eq $true) {
            Write-Host "Full scan is overdue. Starting a full virus scan with Windows Defender..."
            Start-MpScan -ScanType FullScan
        }
        else {
            Write-Host "No scans are overdue. No action taken."
        }
    }

    Write-Log -logFileName "defender_scan_log.txt" -message "Windows Defender ran a scan based on current status" -functionName $MyInvocation.MyCommand.Name
}