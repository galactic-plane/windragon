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

# SYNOPSIS
# Initializes a settings file for managing backup sources and destinations.
# DESCRIPTION
# This function checks if a JSON settings file exists in the current directory. 
# If the file does not exist, it creates one with default values for multiple backup 
# sources and destinations. The function then reads and returns the settings.
# PARAMETERS
# None
# OUTPUTS
# A PowerShell object containing the settings read from the JSON file.
# NOTES
# - Default settings include arrays for multiple sources and destinations.
# - The settings file is saved in JSON format for easy modification and readability.
# EXAMPLE
# $settings = Initialize-Settings
# $sources = $settings.sources
# $destinations = $settings.destinations
function Initialize-Settings {
    # Path to the settings file
    $settingsFilePath = "settings.json"

    # Check if the settings file exists
    if (-not (Test-Path $settingsFilePath)) {
        # Default settings for multiple sources and destinations
        $defaultSettings = @{
            sources      = @("D:\", "Z:\")
            destinations = @("B:\DDrive", "B:\ZDrive")
            backupnore = @(
                ".cache",
                ".docusaurus",
                ".DS_Store",
                ".fusebox",
                ".grunt",
                ".hypothesis",
                ".idea",
                ".ipynb_checkpoints",
                ".mtj.tmp",
                ".mypy_cache",
                ".next",
                ".npm",
                ".nuxt",
                ".nyc_output",
                ".parcel-cache",
                ".pybuilder",
                ".pyre",
                ".ropeproject",
                ".rpt2_cache",
                ".rts2_cache_cjs",
                ".rts2_cache_es",
                ".rts2_cache_umd",
                ".ruff_cache",
                ".scrapy",
                ".serverless",
                ".svelte-kit",
                ".temp",
                ".tox",
                ".vscode",
                ".vscode-test",
                ".vuepress/dist",
                ".webpack",
                ".yarn/cache",
                ".yarn/unplugged",
                ".history",
                "bower_components",
                "build/Release",
                "coverage",
                "dist",
                "docs/_build",
                "env",
                "env.bak",
                "instance",
                "jspm_packages",
                "lib-cov",
                "logs",
                "node_modules",
                "out",
                "profile_default",
                "site",
                "target",
                "venv",
                "venv.bak",
                "vendor"
            )
        }

        # Convert settings to JSON and save to file
        ($defaultSettings | ConvertTo-Json -Depth 3 -Compress) | Set-Content -Path $settingsFilePath

        # Inform the user that a settings file was created
        Write-Host "Settings file created at $settingsFilePath with default values."
    }

    # Read settings from the JSON file and return as a PowerShell object
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

    if ($global:MaintenanceScanRunOnce) {
        Write-Host "Windows Automatic Maintenance has already been initiated. Skipping..."
        return; # Skip if maintenance has already been initiated
    }

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
        if (-not $global:MaintenanceScanRunOnce) {
            Write-Host "Starting Windows Automatic Maintenance..." -ForegroundColor Green            
            & 'C:\Windows\System32\MSchedExe.exe' Start
            Write-Host "Windows Automatic Maintenance started successfully."
            Write-Log -logFileName "maintenance_scan_log" -message "Windows Automatic Maintenance started successfully." -functionName $MyInvocation.MyCommand.Name
            Watch-WindowsMaintenance -TimeoutMinutes 30 -MaxAttempts 120 -MaxWaitSeconds 10
    
            # Set the flag to true after the first run
            $global:MaintenanceScanRunOnce = $true
        }
        else {
            Write-Host "Windows Automatic Maintenance has already been initiated. Skipping..."
            Write-Log -logFileName "maintenance_scan_log" -message "Windows Automatic Maintenance has already been initiated. Skipping..." -functionName $MyInvocation.MyCommand.Name
        }       
    }
    catch {
        $errorDetails = $_.Exception | Out-String 
        Write-Host "Failed to start Windows Automatic Maintenance. Error: $_"
        Write-Log -logFileName "maintenance_scan_log_errors" -message "Maintenance failed: $errorDetails" -functionName $MyInvocation.MyCommand.Name
    }
}

# Function Name: Watch-WindowsMaintenance#
# Description:
#   This function checks if any Windows maintenance processes are currently running.
#   It waits for them to complete before proceeding, utilizing a configurable timeout,
#   maximum attempts, and an exponential backoff wait mechanism.
# Parameters:
#   - TimeoutMinutes (int): The maximum time (in minutes) to wait for the maintenance processes to finish. Default is 0 (no timeout).
#   - MaxAttempts (int): The maximum number of attempts to check the maintenance processes before giving up. Default is 10.
#   - MaxWaitSeconds (int): The maximum wait time (in seconds) between attempts, used in the exponential backoff mechanism. Default is 300 seconds.
# Usage:
#   Watch-WindowsMaintenance -TimeoutMinutes 30 -MaxAttempts 5 -MaxWaitSeconds 120
# Notes:
#   - The function logs messages about its progress and any errors that occur.
#   - If the maintenance processes are still running after reaching the timeout or max attempts, it stops and logs the relevant information.
function Watch-WindowsMaintenance {
    param (
        [int]$TimeoutMinutes = 0,
        [int]$MaxAttempts = 10, # Set a maximum number of attempts to prevent infinite looping
        [int]$MaxWaitSeconds = 10  # Set a configurable maximum wait time (in seconds) for exponential backoff
    )

    Write-Host "Checking the status of Maintenance..."
    Write-Log -logFileName "maintenance_scan_log" -message "Checking the status of Maintenance..." -functionName $MyInvocation.MyCommand.Name

    $startTime = Get-Date
    $attempt = 0

    # List of common maintenance processes
    $maintenanceProcesses = @(
        'defrag', # Disk Defragmenter
        'cleanmgr', # Disk Cleanup
        'dfrgui', # Optimize Drives (Disk Defragmenter GUI)
        'sfc', # System File Checker
        'dism', # Deployment Image Servicing and Management
        'scheduledefrag', # Automatic Scheduled Defragmentation
        'mrt', # Microsoft Malicious Software Removal Tool
        'mpcmdrun'       # Windows Defender (Command Line)
    )


    while ($attempt -lt $MaxAttempts) {
        try {
            # Check if any of the maintenance processes are running
            $runningProcesses = Get-Process -ErrorAction Stop | Where-Object { $maintenanceProcesses -contains $_.Name }
        }
        catch {
            Write-Log -logFileName "maintenance_scan_log" -message "Error occurred while checking maintenance processes: $_" -functionName $MyInvocation.MyCommand.Name
            Start-Sleep -Seconds 5
            continue
        }
        
        if ($runningProcesses.Count -gt 0) {
            $operation = "Maintenance in progress"
            $progressBarLength = 50
            $totalProgress = 100

            for ($i = 1; $i -le $totalProgress; $i++) {
                $progressFill = [int](($i / $totalProgress) * $progressBarLength)
                $emptyFill = $progressBarLength - $progressFill
                $progressBar = '█' * $progressFill + '-' * $emptyFill
                $bytesProcessed = "$(570 + $i)/570"
                $elapsedTime = (Get-Date) - $startTime
                $timeProcessed = "[$($elapsedTime.ToString('hh\:mm\:ss'))]"
                Write-Host -NoNewline "`r${operation}: $i%|$progressBar| $bytesProcessed $timeProcessed"
                Start-Sleep -Milliseconds 100
            }
            Write-Host ""
            Write-Log -logFileName "maintenance_scan_log" -message "Waiting on Maintenance to complete: $($runningProcesses.Name -join ', ')" -functionName $MyInvocation.MyCommand.Name
        }
        else {
            Write-Host "Maintenance is not running."
            Write-Log -logFileName "maintenance_scan_log" -message "Maintenance processes are not running." -functionName $MyInvocation.MyCommand.Name
            break
        }

        # Check if timeout has been reached
        if ($TimeoutMinutes -gt 0) {
            $elapsedTime = (Get-Date) - $startTime
            if ($elapsedTime.TotalMinutes -ge $TimeoutMinutes) {
                Write-Host "Timeout reached. Stopping Maintenance."
                Write-Log -logFileName "maintenance_scan_log" -message "Timeout reached. Stopping Maintenance." -functionName $MyInvocation.MyCommand.Name
                break
            }
        }

        # Wait before checking again using exponential backoff
        $sleepSeconds = [math]::Min([math]::Pow(2, $attempt), $MaxWaitSeconds)  # Cap the wait time using configurable maximum wait time
        Start-Sleep -Seconds $sleepSeconds
        $attempt++
    }

    if ($attempt -ge $MaxAttempts) {
        Write-Host "Maximum number of attempts reached. Exiting."
        Write-Log -logFileName "maintenance_scan_log" -message "Maximum number of attempts reached. Exiting." -functionName $MyInvocation.MyCommand.Name
    }

    Write-Host "Maintenance has completed."
    Write-Log -logFileName "maintenance_scan_log" -message "Maintenance has completed." -functionName $MyInvocation.MyCommand.Name
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

    Add-Type -AssemblyName System.Windows.Forms

    # Create Form
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Width = 350
    $progressForm.Height = 150
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $progressForm.Text = "Processing Tasks..."
    
    # Create Progress Bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(10, 50)
    $progressBar.Size = New-Object System.Drawing.Size(320, 20)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressForm.Controls.Add($progressBar)
    
    # Create Label
    $progressLabel = New-Object System.Windows.Forms.Label
    $progressLabel.Location = New-Object System.Drawing.Point(10, 20)
    $progressLabel.Size = New-Object System.Drawing.Size(320, 20)
    $progressLabel.Text = "0% Complete"
    $progressLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $progressForm.Controls.Add($progressLabel)
    
    # Show Form
    $progressForm.Show()
    
    $totalSteps = $Tasks.Count
    
    for ($i = 0; $i -lt $totalSteps; $i++) {
        $percentComplete = [math]::Round((($i + 1) / $totalSteps) * 100, 2)
        
        # Update Progress Bar and Label
        $progressBar.Value = $percentComplete
        $progressLabel.Text = "$percentComplete% Complete - Task $($i + 1) of $totalSteps"
        
        # Execute the current task with error handling
        try {
            & $Tasks[$i]
        }
        catch {
            Write-Host "Task $($i + 1) failed: $_"
        }

        # Delay between tasks
        if ($i -lt ($totalSteps - 1)) {
            Start-Sleep -Seconds $DelayBetweenTasks
        }
    }
    
    # Close Form
    $progressForm.Close()
}
