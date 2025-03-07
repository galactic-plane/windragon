param (
[int]$RunChoice
)
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
Write-Host "This script must be run as an administrator. Please restart PowerShell with elevated privileges." -ForegroundColor Red
exit
}
$global:ErrorRecords = @()
$global:QuickScanRunOnce = $false
$global:MaintenanceScanRunOnce = $false
Add-Type -AssemblyName System.Windows.Forms
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

# Function Name: Start-Backup

#

# Description:

# This function performs a backup operation using Robocopy. It validates the

# existence of the source and destination directories, creates them if they

# do not exist, and then executes Robocopy to mirror the source to the

# destination. The function also dynamically applies exclusions from the

# backupnore settings provided in the $excludedDirs parameter.

#

# Parameters:

# - source (string): The source directory for the backup.

# - destination (string): The destination directory for the backup.

# - $excludedDirs (string): A backupnore list, which specifies directories and file patterns to exclude.

#

# Features:

# - Validates and creates source/destination paths if they do not exist.

# - Logs the operation and handles errors gracefully.

# - Dynamically applies exclusions based on backupnore settings.

#

# Exit Codes (from Robocopy):

# - 0: No errors, no files copied.

# - 1: Some files copied successfully.

# - 2: Extra files or directories detected.

# - >2: Issues such as mismatched files or errors occurred.

#

# Example Usage:

# $settings = Initialize-Settings

# Start-Backup -source "C:\Source" -destination "D:\Backup" -excludedDirs $excludedDirs

function Start-Backup {

    param (

        [string]$source,

        [string]$destination,

        [string]$excludedDirs

    )



    # Validate and create source and destination paths

    if (-not [System.IO.Directory]::Exists($source)) {

        try {

            Write-Host "Source path '$source' does not exist. Attempting to create it..."

            New-Item -ItemType Directory -Path $source | Out-Null

            Write-Log -logFileName "backup_log" -message "Source path '$source' was missing and has been created." -functionName $MyInvocation.MyCommand.Name

            Show-Message "Source path '$source' was missing and has been created."

        }

        catch {

            Write-Log -logFileName "backup_error_log" -message "Error: Failed to create source path '$source'. $_" -functionName $MyInvocation.MyCommand.Name

            Show-Message "Error: Failed to create source path '$source'."

            return "Robocopy Backup: Failed to create source path."

        }

    }



    if (-not [System.IO.Directory]::Exists($destination)) {

        try {

            Write-Host "Destination path '$destination' does not exist. Attempting to create it..."

            New-Item -ItemType Directory -Path $destination | Out-Null

            Write-Log -logFileName "backup_log" -message "Destination path '$destination' was missing and has been created." -functionName $MyInvocation.MyCommand.Name

            Show-Message "Destination path '$destination' was missing and has been created."

        }

        catch {

            Write-Log -logFileName "backup_error_log" -message "Error: Failed to create destination path '$destination'. $_" -functionName $MyInvocation.MyCommand.Name

            Show-Message "Error: Failed to create destination path '$destination'."

            return "Robocopy Backup: Failed to create destination path."

        }

    }

    

    Show-Message "Starting the backup using Robocopy from $source to $destination..."

    Write-Log -logFileName "backup_log" -message "Starting the backup using Robocopy from $source to $destination..." -functionName $MyInvocation.MyCommand.Name

    try {

        $robocopyArgs = "${source} ${destination} /MIR /FFT /Z /XA:H /W:5 /A-:SH /XD $excludedDirs"

        $robocopyProcess = Start-Process -FilePath "robocopy" -ArgumentList $robocopyArgs -NoNewWindow -Wait -PassThru

        switch ($robocopyProcess.ExitCode) {

            0 {                

                Write-Log -logFileName "backup_log" -message "Backup complete with no errors. Exit code: 0" -functionName $MyInvocation.MyCommand.Name

                Show-Message "Backup complete with no errors. Exit code: 0"

                return "Robocopy Backup: Completed successfully, Exit code: 0"

            }

            1 {                

                Write-Log -logFileName "backup_log" -message "Some files were copied. No errors were encountered. Exit code: 1" -functionName $MyInvocation.MyCommand.Name

                Show-Message "Some files were copied. No errors were encountered. Exit code: 1"

                return "Robocopy Backup: Completed with minor issues, Exit code: 1"

            }

            2 {               

                Write-Log -logFileName "backup_log" -message "Extra files or directories were detected. Exit code: 2" -functionName $MyInvocation.MyCommand.Name

                Show-Message "Extra files or directories were detected. Exit code: 2"

                return "Robocopy Backup: Completed with extra files/directories, Exit code: 2"

            }

            default {                

                Write-Log -logFileName "backup_log" -message "Backup completed with issues. Exit code: $($robocopyProcess.ExitCode)" -functionName $MyInvocation.MyCommand.Name

                Show-Message "Backup completed with issues. Exit code: $($robocopyProcess.ExitCode)"

                return "Robocopy Backup: Completed with issues, Exit code: $($robocopyProcess.ExitCode)"

            }

        }

    }

    catch {

        $errorDetails = $_.Exception | Out-String       

        Write-Log -logFileName "backup_log_errors" -message "Backup failed: $errorDetails" -functionName $MyInvocation.MyCommand.Name

        Catcher -taskName "Backup" -errorMessage $_.Exception.Message

        Show-Error "Robocopy Backup: Failed due to an unexpected error. Please check the log for more information."

        return "Robocopy Backup: Failed due to an unexpected error. Please check the log for more information."

    }

}



# Function: Invoke-All-Backups

# Description: Iterates through all source-destination pairs defined in the settings and performs backups.

# Parameters:

#   [object]$settings: The settings object containing sources and destinations.

# Returns:

#   - None

function Invoke-All-Backups {

    param (

        [object]$settings

    )



    $sources = $settings.sources

    $destinations = $settings.destinations

    $excludedDirs = $settings.backupnore -join ' '



    if ($sources.Count -ne $destinations.Count) {

        Write-Host "Error: The number of sources and destinations must match."

        return

    }



    for ($i = 0; $i -lt $sources.Count; $i++) {

        $source = $sources[$i]

        $destination = $destinations[$i]



        Write-Host "Starting backup for Source: $source -> Destination: $destination"

        Start-Backup -source $source -destination $destination -excludedDirs $excludedDirs

    }

}
# Function to start repair tasks

#

# Function: Start-Repair

# Description: This function performs a series of system repair tasks using various system tools.

#              It includes checking system health, scanning and repairing issues, and performing component cleanup.

#              The function handles and logs any issues encountered during each step for troubleshooting purposes.

# Usage:

#   Start-Repair

function Start-Repair {

    function Invoke-DISMOperation {

        param (

            [string]$OperationName,

            [string]$Arguments

        )

        Write-Log -logFileName "repair_log" -message "Preparing to run $OperationName with arguments: $Arguments" -functionName $MyInvocation.MyCommand.Name

        Show-Message "Running $OperationName using DISM..."

        Start-Process -FilePath 'dism.exe' -ArgumentList $Arguments -NoNewWindow -Wait

        if ($LASTEXITCODE -ne 0) {

            Write-Log -logFileName "repair_log_errors" -message "$OperationName failed with error code $LASTEXITCODE." -functionName $MyInvocation.MyCommand.Name

            return $false

        }

        return $true

    }



    try {

        # DISM CheckHealth

        Invoke-DISMOperation -OperationName "CheckHealth" -Arguments "/Online /Cleanup-Image /CheckHealth"

        # DISM ScanHealth

        Invoke-DISMOperation -OperationName "ScanHealth" -Arguments "/Online /Cleanup-Image /ScanHealth"

        # DISM RestoreHealth

        Invoke-DISMOperation -OperationName "RestoreHealth" -Arguments "/Online /Cleanup-Image /RestoreHealth"



        # Running System File Checker

        Show-Message "Running System File Checker to scan and repair protected system files..."

        try {

            # Validate 'sfc' availability and permissions

            if (-not (Get-Command "sfc" -ErrorAction SilentlyContinue)) {

                Write-Log -logFileName "sfc_log_errors" -message "System File Checker (sfc) executable not found." -functionName $MyInvocation.MyCommand.Name

                Show-Error "System File Checker is not available on this system. Aborting."

                return "System File Checker is not available on this system."

            }



            $startTime = Get-Date

            $sfcProcess = Start-Process -FilePath "sfc" -ArgumentList "/SCANNOW" -NoNewWindow -Wait -PassThru

            $endTime = Get-Date



            Write-Log -logFileName "sfc_log" -message "SFC process started at $startTime and completed at $endTime." -functionName $MyInvocation.MyCommand.Name



            if ($sfcProcess.ExitCode -eq 0) {

                Show-Message "System File Checker has completed successfully."

                return "System File Checker has completed successfully."

            }

            else {

                Write-Log -logFileName "sfc_log_errors" -message "SFC finished with issues. Exit code: $($sfcProcess.ExitCode)" -functionName $MyInvocation.MyCommand.Name

                Show-Error "SFC finished with issues. Exit code: $($sfcProcess.ExitCode). Review the logs or visit the Microsoft support page for additional help."

                return "System File Checker finished with warnings/errors. Exit code: $($sfcProcess.ExitCode)"

            }

        }

        catch {

            $errorDetails = $_.Exception | Out-String

            $sanitizedErrorDetails = ($errorDetails -replace "\s*at .*", "") -replace "\s*in .*", ""

            Catcher -taskName "Repair Tasks" -errorMessage $sanitizedErrorDetails

            Write-Log -logFileName "sfc_log_errors" -message "System File Checker failed: $sanitizedErrorDetails" -functionName $MyInvocation.MyCommand.Name

            Show-Error "System File Checker failed. Please check the log file for more details or consult the troubleshooting guide."

            return "System File Checker failed. Please check the log file for more details."

        }



        # DISM StartComponentCleanup

        Invoke-DISMOperation -OperationName "StartComponentCleanup" -Arguments "/Online /Cleanup-Image /StartComponentCleanup /ResetBase"

    }

    catch {

        $errorDetails = $_.Exception | Out-String

        $sanitizedErrorDetails = ($errorDetails -replace "\s*at .*", "") -replace "\s*in .*", ""

        Write-Log -logFileName "repair_log_errors" -message "Repair tasks failed: $sanitizedErrorDetails" -functionName $MyInvocation.MyCommand.Name

        Catcher -taskName "Repair Tasks" -errorMessage $sanitizedErrorDetails

        Show-Error "Repair tasks failed. Please check the log file for more details. For further assistance, consult the troubleshooting documentation or contact support."

        return "Repair tasks failed. Please check the log file for more details."

    }

}
# Function: Update-AllPackages

# Description: Updates all installed packages from various package managers.

# Parameters: None

# Usage: Update-AllPackages

function Update-AllPackages {

    # Helper function for logging

    function Log {

        param([string]$Message)

        Write-Host $Message -ForegroundColor Green

    }



    # Update Winget packages

    if (Get-Command winget -ErrorAction SilentlyContinue) {

        Log "Updating Winget packages..."

        try {

            winget upgrade --all --accept-source-agreements --ignore-warnings --disable-interactivity

        } catch {

            Write-Host "Error updating Winget packages: $_" -ForegroundColor Red

        }

    } else {

        Write-Host "Winget is not installed." -ForegroundColor Yellow

    }



    # Update Chocolatey packages

    if (Get-Command choco -ErrorAction SilentlyContinue) {

        Log "Updating Chocolatey packages..."

        try {

            choco upgrade all -y

        } catch {

            Write-Host "Error updating Chocolatey packages: $_" -ForegroundColor Red

        }

    } else {

        Write-Host "Chocolatey is not installed." -ForegroundColor Yellow

    }



    # Update Scoop packages

    if (Get-Command scoop -ErrorAction SilentlyContinue) {

        Log "Updating Scoop packages..."

        try {

            scoop update

            scoop update *

        } catch {

            Write-Host "Error updating Scoop packages: $_" -ForegroundColor Red

        }

    } else {

        Write-Host "Scoop is not installed." -ForegroundColor Yellow

    }



   # Update Pip packages

    if (Get-Command pip -ErrorAction SilentlyContinue) {

        Log "Updating Pip packages..."

        try {

            pip list --outdated --format=columns | ForEach-Object {

                $columns = $_ -split '\s+'

                if ($columns[0] -ne "Package" -and $columns[0] -ne "---") {

                    $package = $columns[0]

                    Log "Updating Pip package: $package"

                    pip install --upgrade $package

                }

            }

        } catch {

            Write-Host "Error updating Pip packages: $_" -ForegroundColor Red

        }

    } else {

        Write-Host "Pip is not installed." -ForegroundColor Yellow

    }



    # Update Npm packages

    if (Get-Command npm -ErrorAction SilentlyContinue) {

        Log "Updating global npm packages..."

        try {

            npm update -g

        } catch {

            Write-Host "Error updating global npm packages: $_" -ForegroundColor Red

        }

    } else {

        Write-Host "Npm is not installed." -ForegroundColor Yellow

    }



    # Update .NET Tools

    if (Get-Command dotnet -ErrorAction SilentlyContinue) {

        Log "Updating .NET global tools..."

        try {

            dotnet tool update --global --all

        } catch {

            Write-Host "Error updating .NET global tools: $_" -ForegroundColor Red

        }

    } else {

        Write-Host ".NET SDK is not installed." -ForegroundColor Yellow

    }



    # Update PowerShell modules

    if (Get-Command Update-Module -ErrorAction SilentlyContinue) {

        Log "Updating PowerShell modules..."

        try {

            Get-InstalledModule | ForEach-Object {

                $module = $_.Name

                Log "Updating PowerShell module: $module"

                Update-Module -Name $module -Force

            }

        } catch {

            Write-Host "Error updating PowerShell modules: $_" -ForegroundColor Red

        }

    } else {

        Write-Host "PowerShellGet module is not installed." -ForegroundColor Yellow

    }

}
# Function: Start-Cleanup

# Description: This function executes an advanced disk cleanup using the built-in Windows tool.

#              The function is designed to handle different types of drives and log errors accordingly.

# Parameters: None

# Usage: Start-Cleanup

# Steps:

#   1. Run the Windows disk cleanup utility using preconfigured settings.

function Start-Cleanup {

    try { 

        Clear-RecycleBins

        Show-Message "Starting System Cleanup..."

        # Run advanced disk cleanup using Windows Clean Manager

        Write-Log -logFileName "cleanup_log" -message "Running advanced disk cleanup with preconfigured options..." -functionName $MyInvocation.MyCommand.Name

        try {

            # Start the Clean Manager tool with the specified options

            Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1"            



            # Wait for the cleanup processes to complete

            Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue | Wait-Process



            Write-Log -logFileName "cleanup_log" -message "Advanced disk cleanup complete." -functionName $MyInvocation.MyCommand.Name

            Show-Message "System Cleanup Completed..."

            return "Advanced disk cleanup complete."    

        }

        catch {

            # Log the error if advanced disk cleanup fails

            Catcher -taskName "Start-Cleanup" -errorMessage $_.Exception.Message

            Write-Log -logFileName "cleanup_log" -message "Advanced disk cleanup failed: $_" -functionName $MyInvocation.MyCommand.Name

            Show-Error "System Cleanup Failed..."

            return "Advanced disk cleanup failed: $_"

        }

    }

    catch {

        # Catch any unexpected errors during the cleanup process

        Catcher -taskName "Start-Cleanup" -errorMessage $_.Exception.Message

        Write-Log -logFileName "cleanup_log_errors" -message "Cleanup tasks failed: $_" -functionName $MyInvocation.MyCommand.Name

        Show-Error "System Cleanup Failed..."

        return "Cleanup tasks failed: $_"

    }

}



# Function to empty recycle bins on all partitions#

# SYNOPSIS

#   Empties the recycle bins on all available partitions.#

# DESCRIPTION

#   The Clear-RecycleBins function retrieves all available partitions that have a valid drive letter,

#   are not read-only, and are not system reserved partitions. It then iterates through each partition,

#   attempting to remove the contents of the recycle bin folder located on each drive. The function

#   outputs the status of each operation, either confirming the recycle bin has been emptied or providing

#   an error message if it fails.#

# PARAMETERS

#   None.#

# OUTPUTS

#   String messages indicating the progress of the operation, including any errors encountered.#

# EXAMPLE

#   Clear-RecycleBins

#   This command will empty the recycle bins on all partitions except those that are read-only or system reserved.#

# NOTES

#   - The function makes use of the Remove-Item cmdlet with the -Recurse and -Force flags to ensure all items

#     in the recycle bin are deleted.

#   - The -ErrorAction SilentlyContinue option is used to suppress errors in case the path does not exist.

#   - Write-Host is used instead of Write-Host for better script automation.

function Clear-RecycleBins {

    # Get all partitions that are not read-only, have a valid drive letter, and are not system partitions

    $partitions = Get-Volume | Where-Object { $_.DriveLetter -and -not $_.IsReadOnly -and $_.DriveType -ne 'System' }



    foreach ($partition in $partitions) {

        $driveLetter = $partition.DriveLetter

        

        Write-Host "Emptying Recycle Bin on drive $driveLetter..."



        # Path to the Recycle Bin folder on the drive

        $recycleBinPath = "$driveLetter`:\$Recycle.Bin"



        # Delete the contents of the Recycle Bin folder, ignoring errors if the path does not exist

        try {

            Remove-Item -Path "$recycleBinPath\*" -Recurse -Force -ErrorAction SilentlyContinue

            Write-Host "Recycle Bin on drive $driveLetter has been emptied."

        }

        catch {

            Write-Host "Failed to empty Recycle Bin on drive $driveLetter. Error: $_"

        }

    }

}
# Function: Start-Optimization

# Description: This function performs disk optimization on all physical drives detected by the system. It distinguishes

#              between SSDs and HDDs, applying the appropriate optimization method for each type.

#              For SSDs, it runs the TRIM command to optimize data storage. For HDDs, it performs defragmentation to

#              improve performance. It also logs each action and any errors encountered during the optimization.

# Parameters: None

# Usage: Start-Optimization

# Steps:

#   1. Get all physical disks and filter to only those with a specified MediaType (e.g., SSD, HDD).

#   2. Skip optimization for any unmounted or inaccessible disks.

#   3. For each detected drive:

#       a. If it is an SSD, run TRIM.

#       b. If it is an HDD, run defragmentation.

#   4. Log each step of the optimization process, including successes, failures, and any skipped drives.



function Start-Optimization {

    try {

        Show-Message "Optimizing drives..."

        Write-Log -logFileName "drive_optimization_log" -message "Starting drive optimization process." -functionName $MyInvocation.MyCommand.Name

        try {

            # Get the volumes to optimize, filtering by specific criteria

            $partitions = Get-Volume | Where-Object { $_.DriveLetter -and -not $_.IsReadOnly -and $_.DriveType -ne 'System' }

            

            # Handle the case where no partitions are found

            if ($partitions.Count -eq 0) {

                Write-Host "No volumes found for optimization. Exiting."

                Write-Log -logFileName "drive_optimization_log" -message "No volumes found for optimization. Exiting." -functionName $MyInvocation.MyCommand.Name

                return "No volumes found for optimization. Exiting."

            }



            foreach ($partition in $partitions) {

                # Get the appropriate disk

                $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq (Get-Partition -DriveLetter $partition.DriveLetter).DiskNumber }

                if ($null -ne $disk) {

                    # If the MediaType is SSD, run an Optimize-Volume with the Trim option

                    if ($disk.MediaType -eq "SSD") {

                        Write-Host "Running TRIM on SSD: $($disk.FriendlyName)"

                        Write-Log -logFileName "drive_optimization_log" -message "Running TRIM on SSD: $($disk.FriendlyName)" -functionName $MyInvocation.MyCommand.Name

                        try {

                            Optimize-Volume -DriveLetter $partition.DriveLetter -ReTrim -Verbose

                            Write-Log -logFileName "drive_optimization_log" -message "Successfully optimized SSD: $($disk.FriendlyName)" -functionName $MyInvocation.MyCommand.Name

                        }

                        catch {

                            Show-Error "Failed to optimize SSD: $($disk.FriendlyName). Error: $_"

                            Write-Log -logFileName "drive_optimization_log_errors" -message "Failed to optimize SSD: $($disk.FriendlyName). Error: $_" -functionName $MyInvocation.MyCommand.Name

                            Catcher -taskName "SSD Optimization" -errorMessage $_.Exception.Message

                        }

                    }

                    # If the MediaType is HDD, run a defragmentation operation

                    elseif ($disk.MediaType -eq "HDD") {

                        Write-Host "Running Defrag on HDD: $($disk.FriendlyName)"

                        Write-Log -logFileName "drive_optimization_log" -message "Running Defrag on HDD: $($disk.FriendlyName)"

                        try {

                            Optimize-Volume -DriveLetter $partition.DriveLetter -Defrag -Verbose

                            Write-Log -logFileName "drive_optimization_log" -message "Successfully defragmented HDD: $($disk.FriendlyName)" -functionName $MyInvocation.MyCommand.Name

                        }

                        catch {

                            Show-Error "Failed to defragment HDD: $($disk.FriendlyName). Error: $_"

                            Write-Log -logFileName "drive_optimization_log_errors" -message "Failed to defragment HDD: $($disk.FriendlyName). Error: $_" -functionName $MyInvocation.MyCommand.Name

                            Catcher -taskName "HDD Defragmentation" -errorMessage $_.Exception.Message

                        }

                    }

                }

                else {

                    # Log additional context information for skipped disks

                    $reason = "Disk is either unmounted or inaccessible."

                    Write-Host "Skipping optimization on unmounted or inaccessible partition: $($partition.DriveLetter). Reason: $reason"

                    Write-Log -logFileName "drive_optimization_log" -message "Skipped partition: $($partition.DriveLetter). Reason: $reason" -functionName $MyInvocation.MyCommand.Name

                }

            }

            return "Optimization Completed. Exiting."

        }

        catch {

            Catcher -taskName "Drive Optimization" -errorMessage $_.Exception.Message

            Write-Log -logFileName "drive_optimization_log_errors" -message "Drive optimization failed: $_" -functionName $MyInvocation.MyCommand.Name

            throw

        }

    }

    catch {

        Catcher -taskName "Drive Optimization" -errorMessage $_.Exception.Message

        Write-Log -logFileName "drive_optimization_log_errors" -message "Drive optimization process encountered an unexpected error: $_" -functionName $MyInvocation.MyCommand.Name

        return "Drive Optimization: Failed with error $_"

    }

}
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

    Write-Host "💻🔍 Generating Computer Information..." -ForegroundColor Yellow -BackgroundColor Black

    Write-Host "`n"



    Show-Message "✨ System Information ✨" -ForegroundColor White -BackgroundColor DarkBlue

    try {

        # Log and display Basic system information

        $basicInfo = Get-ComputerInfo | Select-Object CSName, WindowsVersion, OSArchitecture, WindowsBuildLabEx

        $basicInfo | ForEach-Object {

            $_ | Format-List | Out-String | ForEach-Object {

                Write-Host $_ -ForegroundColor White

                Write-Log -logFileName "system_info_log" -message "BasicSystemInfo: $_" -functionName "Get-ComputerInfo"

            }

        }

    }

    catch {

        Write-Host "Error retrieving basic system information: $_" -ForegroundColor Red

        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"

    }



    Write-Host "`n"



    Show-Message "🔥 CPU Information 🔥" -ForegroundColor Yellow -BackgroundColor DarkGreen

    try {

        # Log and display CPU information

        $cpuInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed

        $cpuInfo | ForEach-Object {

            $_ | Format-List | Out-String | ForEach-Object {

                Write-Host $_ -ForegroundColor Yellow

                Write-Log -logFileName "system_info_log" -message "CPUInfo: $_" -functionName "Get-CimInstance (CPU)"

            }

        }

    }

    catch {

        Write-Host "Error retrieving basic system information: $_" -ForegroundColor Red

        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"

    }



    Write-Host "`n"



    Show-Message "🌱 Memory Information 🌱" -ForegroundColor Green -BackgroundColor DarkYellow

    try {

        # Log and display Memory information

        $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object Manufacturer, Capacity, Speed, MemoryType

        $memoryInfo | ForEach-Object {

            $_ | Format-List | Out-String | ForEach-Object {

                Write-Host $_ -ForegroundColor Green

                Write-Log -logFileName "system_info_log" -message "MemoryInfo: $_" -functionName "Get-CimInstance (Memory)"

            }

        }

    }

    catch {

        Write-Host "Error retrieving basic system information: $_" -ForegroundColor Red

        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"

    }



    Write-Host "`n"



    Show-Message "💾 Disk Information 💾" -ForegroundColor Cyan -BackgroundColor DarkRed

    try {

        # Log and display Disk information

        $diskInfo = Get-CimInstance -ClassName Win32_DiskDrive | Select-Object DeviceID, Model, Size

        $diskInfo | ForEach-Object {

            $_ | Format-List | Out-String | ForEach-Object {

                Write-Host $_ -ForegroundColor Cyan

                Write-Log -logFileName "system_info_log" -message "DiskInfo: $_" -functionName "Get-CimInstance (Disk)"

            }

        }

    }

    catch {

        Write-Host "Error retrieving basic system information: $_" -ForegroundColor Red

        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"

    }



    Write-Host "`n"



    Show-Message "🌐 Network Adapter Information 🌐" -ForegroundColor Gray -BackgroundColor DarkMagenta

    try {

        # Log and display Network adapter information

        $networkInfo = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object Name, MACAddress, LinkSpeed

        $networkInfo | ForEach-Object {

            $_ | Format-List | Out-String | ForEach-Object {

                Write-Host $_ -ForegroundColor Gray

                Write-Log -logFileName "system_info_log" -message "NetworkInfo: $_" -functionName "Get-NetAdapter (Network)"

            }

        }

    }

    catch {

        Write-Host "Error retrieving basic system information: $_" -ForegroundColor Red

        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"

    }



    Write-Host "`n"



    Show-Message "🖥️ OS Details 🖥️" -ForegroundColor White -BackgroundColor DarkGreen

    try {

        # Log and display Operating system details

        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem

        $osInfo | ForEach-Object {

            $_ | Format-List | Out-String | ForEach-Object {

                Write-Host $_ -ForegroundColor White

                Write-Log -logFileName "system_info_log" -message "OSInfo: $_" -functionName "Get-CimInstance (OS)"

            }

        }

    }

    catch {

        Write-Host "Error retrieving basic system information: $_" -ForegroundColor Red

        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"

    }



    Write-Host "`n"



    Show-Message "📜 BIOS Information 📜" -ForegroundColor Yellow -BackgroundColor DarkCyan

    try {

        # Log and display BIOS information

        $biosInfo = Get-CimInstance -ClassName Win32_BIOS

        $biosInfo | ForEach-Object {

            $_ | Format-List | Out-String | ForEach-Object {

                Write-Host $_ -ForegroundColor Yellow

                Write-Log -logFileName "system_info_log" -message "BIOSInfo: $_" -functionName "Get-CimInstance (BIOS)"

            }

        }

    }

    catch {

        Write-Host "Error retrieving basic system information: $_" -ForegroundColor Red

        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"

    }



    Write-Host "`n"



    Show-Message "🎨 GPU Information 🎨" -ForegroundColor Blue -BackgroundColor DarkYellow

    try {

        # Log and display GPU information

        $gpuInfo = Get-CimInstance -ClassName Win32_VideoController

        $gpuInfo | ForEach-Object {

            $_ | Format-List | Out-String | ForEach-Object {

                Write-Host $_ -ForegroundColor Blue

                Write-Log -logFileName "system_info_log" -message "GPUInfo: $_" -functionName "Get-CimInstance (GPU)"

            }

        }

    }

    catch {

        Write-Host "Error retrieving basic system information: $_" -ForegroundColor Red

        Write-Log -logFileName "system_info_log" -message "Error retrieving basic system information: $_" -functionName "Get-ComputerInfo"

    }



    Write-Host "`n"



    Write-Host "✅ Computer Information Collection Completed Successfully! ✅" -ForegroundColor Green -BackgroundColor Black

}
# Function: Search-OnlineForInfo

# Description: This function takes a message string and generates a Bing search URL for the given information.

#              It is used to create online search links for specific hardware properties, such as Name, Manufacturer, Model, etc., for easy online reference.

# Parameters:

#   - $message: The string containing the hardware information to search for.

# Returns: A URL string that points to a Bing search for the provided message.

# Process:

#   1. Checks if the message contains a period and trims it accordingly.

#   2. Constructs a hashtable with parameters for the Bing search query.

#   3. Builds a query string by encoding the parameters.

#   4. Constructs the full request URL.

#   5. Returns the constructed URL.



function Search-OnlineForInfo ($message) {

    $encodedMessage = if ($message -contains '.') { $message.Split('.')[0].Trim('"') } else { $message.Trim('"') }



    # Define parameters as a hashtable

    $parameters = @{

        q    = $encodedMessage

        shm  = "cr"

        form = "DEEPSH"

    }



    # Build the query string by encoding each parameter

    $queryString = ($parameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$([uri]::EscapeDataString($_.Value))" }) -join '&'

    

    # Construct the full request URL directly

    $requestUrl = "https://www.bing.com/search?$queryString"



    return "$requestUrl"

}



# Function: Get-EventLogEntries

# Description: Retrieves event log entries based on the specified log name and event level.

# Parameters:

#   - [string]$logName: The name of the event log to query.

#   - [int]$level: The level of events to filter (e.g., 1 for critical, 2 for error).

#   - [int]$maxEvents: The maximum number of events to retrieve (default is 10).

# Returns: An array of custom objects containing event log details.

# Usage: $entries = Get-EventLogEntries -logName "System" -level 1 -maxEvents 10

function Get-EventLogEntries {

    param (

        [string]$logName,

        [int]$level,

        [int]$maxEvents = 10

    )

    try {      

        

        $events = Get-WinEvent -LogName System -FilterXPath "*[System/Level=$level]" -MaxEvents $maxEvents | ForEach-Object {

            [PSCustomObject]@{

                TimeCreated  = $_.TimeCreated

                ProviderName = $_.ProviderName

                Id           = $_.Id

                Message      = $_.Message                

            }

        }

        

        if ($events) {

            return $events

        }

        else {

            Write-Log -logFileName "event_log_analysis" -message "No events found for level $level in $logName." -functionName "Get-EventLogEntries"

            return @()

        }

    }

    catch {

        Write-Log -logFileName "event_log_analysis_errors" -message "Error querying events for level $level in ${logName}: $_" -functionName "Get-EventLogEntries"

        return @()

    }

}





# Function: Show-EventLogEntries

# Description: Displays event log entries with detailed information and logs the analysis.

# Parameters:

#   - [string]$title: The title to display before showing the event log entries.

#   - [array]$entries: An array of event log entries to display.

#   - [string]$color: The color to use for displaying the event log entries.

# Usage:

#   $entries = Get-EventLogEntries -logName "Application" -level 2 -maxEvents 10

#   Show-EventLogEntries -title "Recent Application Events" -entries $entries -color Yellow

function Show-EventLogEntries {

    param (

        [string]$title,

        [array]$entries,

        [string]$color

    )

    if ($entries.Count -gt 0) {

        Show-Message $title

        $entries | ForEach-Object {

            Write-Host "============================================================" -ForegroundColor $color

            Write-Host "🕒 Time Created: $($_.TimeCreated)" -ForegroundColor Cyan

            Write-Host "🔌 Provider: $($_.ProviderName)" -ForegroundColor Cyan

            Write-Host "🆔 Id: $($_.Id)" -ForegroundColor Cyan

            Write-Host "💬 Message: $($_.Message)" -ForegroundColor Cyan

            $onlineInfo = Search-OnlineForInfo -message $($_.Message)

            Write-Host "🌐 Mitigation Info: $onlineInfo" -ForegroundColor Green

            Write-Log -logFileName "event_log_analysis" -message "${title}: TimeCreated: $($_.TimeCreated) - Provider: $($_.ProviderName) - Id: $($_.Id) - Message: $($_.Message)" -functionName "Show-EventLogEntries"

        }

    }

    else {

        Show-Message "No events found for $title."

    }

}



# Function: Start-EventLogAnalysis

# Description: Analyzes the system event logs for critical events and errors.

#              Retrieves critical and error events from the system event log and displays them.

#              If an error occurs during the analysis, it logs the error details and shows an error message.

# Parameters: None

# Usage: Start-EventLogAnalysis

# Example:

#   Start-EventLogAnalysis

#   This command starts the analysis of the system event logs and displays the critical and error events.

function Start-EventLogAnalysis {

    Show-Message "🚀 Analyzing Event Logs... Please wait..."

    try {

        $systemLogErrors = Get-EventLogEntries -logName "System" -level 2 -maxEvents 10

        Show-EventLogEntries -title "🔥 System Log Errors (Last 10) 🔥" -entries $systemLogErrors -color "Magenta"

    }

    catch {

        $errorDetails = $_.Exception | Out-String

        Write-Log -logFileName "event_log_analysis_errors" -message "❌ Event log analysis failed: $errorDetails" -functionName "Start-EventLogAnalysis"

        Catcher -taskName "Event Log Analysis" -errorMessage $_.Exception.Message

        Show-Error "❌ Event log analysis failed. Please check the log file for more details."

    }

}
function Show-Dragon {
    $dragon = @"
                         ___====-_  _-====___
                   _--^^^#####//      \\#####^^^--_
                _-^##########// (    ) \\##########^-_
               -############//  |\^^/|  \\############-
             _/############//   (@::@)   \\############\_
            /#############((     \\//     ))#############\
           -###############\\    (oo)    //###############-
          -#################\\  / "  \  //#################-
         -###################\/      \//###################-
        _#/|##########/\######(   /\   )######/\##########|\#_
       |/ |#/#\#/#\/  \#/#\##\  \ \_/ /  ##/#\/#\/  \#/\#/ #\|
       ||/  V  '  `-'  V  \#\|  |\| | |\ |#/V  `-'   '  V  \||
       |||                \#|   | | | | \|#/               |||
       |||                 V    | | | |  V                |||
       |||                      ' | | '                   |||
       |||                       "  '                     |||
       |||                                               |||
       |||                                               |||
       |||                                               |||
     , |'|                                               |'| ,
    /.\/ /                                               \ \'.\
   /// //                                                 \ \\\\
  ||| '\'                                                 /'/ |||
                _   _   _   _   _   _   _   _   _
               / \ / \ / \ / \ / \ / \ / \ / \ / \
              ( W | i | n | D | r | a | g | o | n )
               \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ vBeta
"@
    Write-Host $dragon -ForegroundColor Yellow
}

function Show-Message {
param (
[ValidateNotNullOrEmpty()]
[string]$message
)
try {
$border = '�' * ($message.Length)
Write-Host "┌$border┐" -ForegroundColor Yellow
Write-Host " $message " -ForegroundColor Yellow
Write-Host "└$border┘" -ForegroundColor Yellow
}
catch {
Write-Host "An error occurred while displaying the message." -ForegroundColor Red
}
}
function Show-Error {
param (
[ValidateNotNullOrEmpty()]
[string]$message
)
try {
$border = '�' * ($message.Length)
Write-Host "┌$border┐" -ForegroundColor Red
Write-Host " $message " -ForegroundColor Red
Write-Host "└$border┘" -ForegroundColor Red
}
catch {
Write-Host "An error occurred while displaying the error message." -ForegroundColor Red
}
}
function Show-Menu {
ResetConsoleScreen
    Show-Dragon
Write-Host "`n"
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "                 SYSTEM TASK MENU                               " -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please select an option:" -ForegroundColor Green
Write-Host ""
Write-Host "  1. Start Mirror Backup" -ForegroundColor White
Write-Host "  2. Start Repair Tasks (DISM and SFC)" -ForegroundColor White
Write-Host "  3. Update Installed Software" -ForegroundColor White
Write-Host "  4. Start Cleanup Tasks" -ForegroundColor White
Write-Host "  5. Start Drive Optimization" -ForegroundColor White
Write-Host "  6. Get System Information" -ForegroundColor White
Write-Host "  7. Analyze Event Logs" -ForegroundColor White
Write-Host "  8. Start All Tasks (Except Backup)" -ForegroundColor White
Write-Host "  9. Start All Tasks" -ForegroundColor White
Write-Host " 10. Exit" -ForegroundColor White
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
$choice = Read-Host "Enter the number of your choice"
return $choice
}
function Initialize-Tasks {
param (
[string]$choice,
[object]$settings
)
$tasks = @()
switch ($choice) {
"1" {
$tasks = @(
{ Write-Host "Mirror Backup selected." },
{ Write-Host "Perform Pre-Backup Tasks" },
{ Start-DefenderScan -ScanType QuickScan },
{ Write-Host "Performing Mirror Backup." },
{ $operationStatus += Invoke-All-Backups -settings $settings }
)
}
"2" {
$tasks = @(
{ Write-Host "Repair tasks selected." },
{ Write-Host "Perform Pre-Repair Tasks" },
{ Start-DefenderScan -ScanType QuickScan },
{ Start-WindowsMaintenance },
{ $operationStatus += Start-Repair }
)
}
"3" {
$tasks = @(
{ Write-Host "Update Apps tasks selected." },
{ Write-Host "Perform Pre-UpdateApps Tasks" },
{ Start-DefenderScan -ScanType QuickScan },
{ Start-WindowsMaintenance },
{ $operationStatus += Update-AllPackages }
)
}
"4" {
$tasks = @(
{ Write-Host "Cleanup tasks selected." },
{ Write-Host "Perform Pre-Cleanup Tasks" },
{ Start-DefenderScan -ScanType QuickScan },
{ Start-WindowsMaintenance },
{ $operationStatus += Start-Cleanup }
)
}
"5" {
$tasks = @(
{ Write-Host "Drive optimization selected." },
{ Write-Host "Perform Pre-Optimization Tasks" },
{ Start-DefenderScan -ScanType QuickScan },
{ Start-WindowsMaintenance },
{ $operationStatus += Start-Optimization }
)
}
"6" {
$tasks = @(
{ Write-Host "Getting Computer Information" },
{ Start-PCInfo }
)
}
"7" {
$tasks = @(
{ Write-Host "Analyzing Event Logs..." },
{ Start-EventLogAnalysis }
)
}
"8" {
$tasks = @(
{ Write-Host "Performing all tasks (Except Mirror Backup)." },
{ Write-Host "Perform Pre-Operation Tasks" },
{ Start-DefenderScan -ScanType QuickScan },
{ Start-WindowsMaintenance },
{ $operationStatus += Start-Repair },
{ $operationStatus += Update-AllPackages },
{ $operationStatus += Start-Cleanup },
{ $operationStatus += Start-Optimization },
{ Start-PCInfo },
{ Start-EventLogAnalysis }
)
}
"9" {
$tasks = @(
{ Write-Host "Performing all tasks." },
{ Write-Host "Perform Pre-Operation Tasks" },
{ Start-DefenderScan -ScanType QuickScan },
{ Start-WindowsMaintenance },
{ Invoke-All-Backups -settings $settings },
{ $operationStatus += Start-Repair },
{ $operationStatus += Update-AllPackages },
{ $operationStatus += Start-Cleanup },
{ $operationStatus += Start-Optimization },
{ Start-PCInfo },
{ Start-EventLogAnalysis }
)
}
"10" {
ResetConsoleScreen
exit
}
default {
Write-Host "Invalid selection. Please choose an option from the menu."
}
}
return $tasks
}
if ($RunChoice) {
$settings = Initialize-Settings
$tasks = Initialize-Tasks -choice $RunChoice.ToString() -settings $settings
if ($tasks) {
Show-ProgressBar -Tasks $tasks -DelayBetweenTasks 2
}
exit
}
else {
ResetConsoleScreen
    Show-Dragon
Write-Host "`n"
Show-Message "Disclaimer: You are running this script at your own risk."
Write-Host "`n"
$confirmation = Read-Host "Please type 'Y' to confirm: "
if ($confirmation -ne 'Y') {
Show-Error "User did not confirm. Exiting script."
exit
}
$settings = Initialize-Settings
do {
$global:ErrorRecords = @()
$operationStatus = @()
$choice = Show-Menu
$tasks = Initialize-Tasks -choice $choice -settings $settings
if ($tasks) {
Show-ProgressBar -Tasks $tasks -DelayBetweenTasks 2
}
else {
Write-Host "Invalid selection. Please choose an option from the menu."
}
if ($operationStatus) {
foreach ($status in $operationStatus) {
if (-not ($status -is [int]) -and -not ($status -is [System.Int64])) {
Write-Log -logFileName "completed" -message $status -functionName $MyInvocation.MyCommand.Name
}
}
}
if ($global:ErrorRecords.Count -gt 0) {
foreach ($err in $global:ErrorRecords) {
if (-not ($status -is [int]) -and -not ($status -is [System.Int64])) {
Write-Log -logFileName "errors" -message $status -functionName $MyInvocation.MyCommand.Name
}
}
}
Pause
} while ($true)
}