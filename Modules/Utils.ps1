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
    $startTime = Get-Date # Record the start time to estimate remaining time

    for ($i = 0; $i -lt $totalSteps; $i++) {
        $elapsedTime = (Get-Date) - $startTime # Calculate elapsed time
        $averageTimePerTask = if ($i -eq 0) { $DelayBetweenTasks } else { $elapsedTime.TotalSeconds / $i } # Use delay as initial estimate for average time per task
        $estimatedRemainingTime = [timespan]::FromSeconds($averageTimePerTask * ($totalSteps - $i)) # Estimate remaining time

        $percentComplete = [math]::Round((($i + 1) / $totalSteps) * 100, 2) # Calculate the percentage complete and round to 2 decimal places

        # Update the progress bar with the current status
        Write-Progress -Activity 'Executing Tasks' `
            -Status "Executing Task $($i + 1) of $totalSteps - Estimated Time Remaining: $([math]::Round($estimatedRemainingTime.TotalSeconds, 0)) seconds" `
            -PercentComplete $percentComplete

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
