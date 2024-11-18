# SYNOPSIS
#     Moves the cursor to the top-left corner of the console and clears the screen.
# SYNTAX
#     ResetConsoleScreen
# DESCRIPTION
#     The ResetConsoleScreen function sets the cursor position to the top-left corner of the console window
#     and clears the console screen.
# EXAMPLES
#     Example 1:
#     ResetConsoleScreen
#     This command moves the cursor to the top-left corner of the console and clears the screen.
function ResetConsoleScreen {
    # Moves the cursor to the top-left corner of the console and clears the screen
    [System.Console]::Clear()
}

# Initializes the settings by creating a settings file with default values if it doesn't exist.
# Returns the settings read from the settings file.
function Initialize-Settings {
    # Create a settings file for default paths
    $settingsFilePath = "settings.json"

    # Check if settings file exists, if not, create it with default values
    if (-not (Test-Path $settingsFilePath)) {
        $defaultSettings = @{
            defaultSource      = "D:\\"
            defaultDestination = "B:\\DayAfter"
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
    Write-Log -logFileName 'error_log' -message "Error in task: $taskName - $errorMessage" -functionName $taskName
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
#   Write-Log -logFileName "repair_log" -message "Repair task started successfully." -functionName "Start-Repair"
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
            Show-Error "Failed to create log directory '$logDirectory' due to insufficient permissions. Please check permissions."
            return
        }
        catch [System.IO.IOException] {
            Show-Error "Failed to create log directory '$logDirectory' due to an I/O error. Please verify the path and ensure there are no conflicts."
            return
        }
        catch {
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

    Write-Log -logFileName "defender_scan_log" -message "Windows Defender ran a scan based on current status" -functionName $MyInvocation.MyCommand.Name
}

# Function to start Windows maintenance tasks
#
# Function: Start-WindowsMaintenance
# Description: This function initiates the Windows maintenance process by ensuring the Task Scheduler service is running. 
#              If the service is not running, it attempts to start it with a retry mechanism. Once the service is confirmed to be running,
#              it initiates Windows Automatic Maintenance. The function logs the progress and errors encountered during execution.
# Parameters: None
# Returns: None
# Usage: Start-WindowsMaintenance
function Start-WindowsMaintenance {
    # Check if Task Scheduler service is running
    $serviceName = 'Schedule'
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if ($null -eq $service) {
        Write-Host "The Task Scheduler service ($serviceName) is not found on this system."
        Write-Log -logFileName "maintenance_scan_log" -message "The Task Scheduler service ($serviceName) is not found on this system." -functionName $MyInvocation.MyCommand.Name
        return
    }

    if ($service.Status -ne 'Running') {
        Write-Host "The Task Scheduler service ($serviceName) is not running. Starting it now..."
        Write-Log -logFileName "maintenance_scan_log" -message "The Task Scheduler service ($serviceName) is not running. Starting it now..." -functionName $MyInvocation.MyCommand.Name
        $maxRetries = 3
        $retryCount = 0
        while ($retryCount -lt $maxRetries) {
            try {
                Start-Service -Name $serviceName
                Write-Host "Task Scheduler service started successfully."
                Write-Log -logFileName "maintenance_scan_log" -message "Task Scheduler service started successfully." -functionName $MyInvocation.MyCommand.Name
                break
            }
            catch {
                # Enhanced logging for troubleshooting
                $errorDetails = $_.Exception | Out-String 
                Write-Host "Failed to start the Task Scheduler service. Attempt $($retryCount + 1) of $maxRetries. Error: $_"
                Write-Log -logFileName "maintenance_scan_log_errors" -message "Maintenance failed: $errorDetails" -functionName $MyInvocation.MyCommand.Name
                $retryCount++
                if ($retryCount -ge $maxRetries) {
                    Write-Host "Reached maximum retry attempts. Could not start the Task Scheduler service."
                    Write-Log -logFileName "maintenance_scan_log" -message "Reached maximum retry attempts. Could not start the Task Scheduler service." -functionName $MyInvocation.MyCommand.Name
                    return
                }
                Start-Sleep -Seconds 5
            }
        }
    }   

    # Trigger Automatic Maintenance
    try {
        & 'C:\Windows\System32\MSchedExe.exe' Start
        Write-Host "Windows Automatic Maintenance started successfully."
        Write-Log -logFileName "maintenance_scan_log" -message "Windows Automatic Maintenance started successfully." -functionName $MyInvocation.MyCommand.Name
    }
    catch {
        $errorDetails = $_.Exception | Out-String 
        Write-Host "Failed to start Windows Automatic Maintenance. Error: $_"
        Write-Log -logFileName "maintenance_scan_log_errors" -message "Maintenance failed: $errorDetails" -functionName $MyInvocation.MyCommand.Name
    }
}

# This function displays a progress bar while executing a series of tasks sequentially.
# Each task is represented as a script block and is executed in the order provided.
# The progress bar updates dynamically to reflect the completion status of each task.
# A delay can be introduced between tasks, and the screen is cleared after each delay.
# 
# Parameters:
# - Tasks: An array of script blocks representing the tasks to execute.
# - DelayBetweenTasks: The delay in seconds between tasks (default is 2 seconds).
# 
# Example:
# $tasks = @(
#     { Write-Host "Task 1 running..."; Start-Sleep -Seconds 2 },
#     { Write-Host "Task 2 running..."; Start-Sleep -Seconds 2 },
#     { Write-Host "Task 3 running..."; Start-Sleep -Seconds 2 }
# )
# Show-ProgressBar -Tasks $tasks -DelayBetweenTasks 3
# 
# The progress bar will update for each task, and there will be a 3-second delay
# with the screen clearing after each task (except the last).
function Show-ProgressBar {
    param (
        [array]$Tasks, # An array of tasks to execute
        [int]$DelayBetweenTasks = 2  # Delay in seconds between tasks (default is 2 seconds)
    )

    $totalSteps = $Tasks.Count # Determine the total number of steps based on the task count

    for ($i = 0; $i -lt $totalSteps; $i++) {
        ResetConsoleScreen # Clear the console screen for a clean display
        $percentComplete = [math]::Round((($i + 1) / $totalSteps) * 100, 2) # Calculate the percentage complete and round to 2 decimal places
        # Enhanced custom progress bar
        $barLength = 50 # Length of the progress bar in characters
        $filledLength = [math]::Round(($percentComplete / 100) * $barLength)
        $progressBar = "".PadLeft($filledLength, '█') + "".PadRight($barLength - $filledLength, '░') # Use solid and light blocks for a visual enhancement
        
        # Progress bar display with task information
        Write-Host "`r" -NoNewline
        Write-Host "[" -NoNewline -ForegroundColor Yellow
        Write-Host "$progressBar" -NoNewline -ForegroundColor Green
        Write-Host "]" -NoNewline -ForegroundColor Yellow
        Write-Host " $percentComplete% - " -NoNewline -ForegroundColor Yellow
        Write-Host "Executing:" -NoNewline -ForegroundColor White
        Write-Host " - Task $($i + 1) of $totalSteps" -NoNewline -ForegroundColor Yellow
        Write-Host "`n"
        Write-Host "`n"

        # Execute the current task with error handling
        try {
            & $Tasks[$i]
        }
        catch {
            Write-Log -logFileName "task_errors" -message "Task $($i + 1) failed: $_" -functionName $MyInvocation.MyCommand.Name
            Write-Error "Task $($i + 1) failed: $_"
        }

        # Delay and clear screen after each task, but keep progress bar at the top
        if ($i -lt ($totalSteps - 1)) {
            Start-Sleep -Seconds $DelayBetweenTasks
        }
    }
}
