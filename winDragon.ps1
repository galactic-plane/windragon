# WinDragon Maintenance Script - vBeta
# Author: Daniel Penrod
# This script provides an interactive menu-driven interface for performing various maintenance tasks on a Windows machine.
# Tasks include backup, repair, cleanup, drive optimization, or all tasks sequentially.

# Supported Operating Systems:
# - Windows 11
# Note: This script relies on PowerShell commands and tools like DISM, Robocopy, and SFC, which are supported on the above-listed versions of Windows.

# How to Run the Script:
# 1. Open PowerShell as an Administrator.
# 2. Navigate to the directory where this script is located.
#    - Use the 'cd' command to change directories. Example: `cd C:\path\to\script`
# 3. Run the script by typing: `\.\winDragon.ps1`
# 4. Follow the interactive prompts to select the tasks you wish to perform.

# Tip: It is best to run this script from a USB thumb drive to ensure that the script can access all necessary files without restrictions.

# Requirements:
# - PowerShell 7.4.6 or newer
# - Administrator privileges to perform system-level operations like repair, cleanup, and optimization.

# Function to ensure script is running with admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as an administrator. Please restart PowerShell with elevated privileges." -ForegroundColor Red
    exit
}

# Global variable for storing error records
$global:ErrorRecords = @()
# Global variable to ensure the quick scan runs at least once
$global:QuickScanRunOnce = $false

# Function to show ASCII Dragon
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

# Function: Show-Message
# Description: Displays a message with a decorative border in yellow color.
# Parameters: 
#   - $message (string): The message to be displayed.
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

# Function: Show-Error
# Description: Displays an error message with a decorative border in red color.
# Parameters: 
#   - $message (string): The error message to be displayed.
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

# Function: Show-Menu
# Description: This function displays a task menu for the user.
#              It provides multiple options for system maintenance tasks such as backups,
#              software updates, drive optimization, and system information retrieval.
#              The user is prompted to enter a selection, which is then returned for further processing.
function Show-Menu {
    Clear-Host
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

# Function: Get-BackupPaths
# Description: This function prompts the user to enter the source and destination directories for a backup operation.
# If the user does not provide input, the function will use default values obtained from a settings file.
# Parameters:
#   - [string] $defaultSource: Default source directory for backup (retrieved from the settings file).
#   - [string] $defaultDestination: Default destination directory for backup (retrieved from the settings file).
# Returns:
#   - An array containing the source and destination directory paths.
function Get-BackupPaths {
    param (
        [string]$defaultSource = $settings.defaultSource,
        [string]$defaultDestination = $settings.defaultDestination
    )
    $source = Read-Host "Enter the source directory for backup (default: $defaultSource)"
    $destination = Read-Host "Enter the destination directory for backup (default: $defaultDestination)"
    
    if (-not $source) { $source = $defaultSource }
    if (-not $destination) { $destination = $defaultDestination }

    return @($source, $destination)
}

# Function: Catcher
# Description: This function is used to handle errors that occur during various tasks and collect those errors for a summary report.
# It takes in the task name and error message as parameters, validates them to ensure they are not null or empty, and then logs the error.
# The error details are also appended to a global error collection, and a log entry is created for record-keeping.
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

# Function to start backup tasks
#
# Function: Start-Backup
# Description: This function initiates a backup operation using Robocopy to copy files from a source directory to a destination directory.
#              It validates the paths before starting the backup, executes the Robocopy command, and handles different exit codes to
#              provide meaningful feedback about the success or failure of the backup process. Additionally, it logs any errors that occur.
# Parameters:
#   [string]$source - The path to the source directory that will be backed up.
#   [string]$destination - The path to the destination directory where the backup will be stored.
# Returns:
#   A string message indicating the status of the backup, including success, failure, or issues encountered.
# Usage:
#   Start-Backup -source "C:\SourceFolder" -destination "D:\DestinationFolder"
function Start-Backup {
    param (
        [string]$source,
        [string]$destination
    )
            
    # Validate source and destination paths
    if (-not [System.IO.Directory]::Exists($source)) {
        Write-Log -logFileName "backup_error_log.txt" -message "Error: Source path '$source' is invalid or does not exist." -functionName $MyInvocation.MyCommand.Name
        Show-Message "Error: Source path '$source' is invalid or does not exist."
        return "Robocopy Backup: Failed due to invalid source path."
    }
    
    if (-not [System.IO.Directory]::Exists($destination)) {        
        Write-Log -logFileName "backup_error_log.txt" -message "Error: Destination path '$destination' is invalid or does not exist." -functionName $MyInvocation.MyCommand.Name
        Show-Message "Error: Destination path '$destination' is invalid or does not exist."
        return "Robocopy Backup: Failed due to invalid destination path."
    }
    
    Show-Message "Starting the backup using Robocopy from $source to $destination..."
    Write-Log -logFileName "backup_log.txt" -message "Starting the backup using Robocopy from $source to $destination..." -functionName $MyInvocation.MyCommand.Name
    try {
        $robocopyProcess = Start-Process -FilePath "robocopy" -ArgumentList "${source} ${destination} /MIR /R:3 /W:10" -NoNewWindow -Wait -PassThru
        switch ($robocopyProcess.ExitCode) {
            0 {                
                Write-Log -logFileName "backup_log.txt" -message "Backup complete with no errors. Exit code: 0" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Backup complete with no errors. Exit code: 0"
                return "Robocopy Backup: Completed successfully, Exit code: 0"
            }
            1 {                
                Write-Log -logFileName "backup_log.txt" -message "Some files were copied. No errors were encountered. Exit code: 1" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Some files were copied. No errors were encountered. Exit code: 1"
                return "Robocopy Backup: Completed with minor issues, Exit code: 1"
            }
            2 {               
                Write-Log -logFileName "backup_log.txt" -message "Extra files or directories were detected. Exit code: 2" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Extra files or directories were detected. Exit code: 2"
                return "Robocopy Backup: Completed with extra files/directories, Exit code: 2"
            }
            3 {                
                Write-Log -logFileName "backup_log.txt" -message "Some files were copied and extra files were detected. Exit code: 3" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Some files were copied and extra files were detected. Exit code: 3"
                return "Robocopy Backup: Completed with some issues, Exit code: 3"
            }
            5 {               
                Write-Log -logFileName "backup_log.txt" -message "Some files were mismatched. No files were copied. Exit code: 5" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Some files were mismatched. No files were copied. Exit code: 5"
                return "Robocopy Backup: Completed with mismatched files, Exit code: 5"
            }
            6 {                
                Write-Log -logFileName "backup_log.txt" -message "Additional files or directories were detected and mismatched. Exit code: 6" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Additional files or directories were detected and mismatched. Exit code: 6"
                return "Robocopy Backup: Completed with mismatched files and extra files, Exit code: 6"
            }
            7 {                
                Write-Log -logFileName "backup_log.txt" -message "Files were copied, mismatched, and extra files were detected. Exit code: 7" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Files were copied, mismatched, and extra files were detected. Exit code: 7"
                return "Robocopy Backup: Completed with several issues, Exit code: 7"
            }
            8 {               
                Write-Log -logFileName "backup_log.txt" -message "Backup completed with some files/directories mismatch. Exit code: 8" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Backup completed with some files/directories mismatch. Exit code: 8"
                return "Robocopy Backup: Completed with issues, Exit code: 8"
            }
            16 {                
                Write-Log -logFileName "backup_log.txt" -message "Backup completed with serious errors. Exit code: 16" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Backup completed with serious errors. Exit code: 16"
                return "Robocopy Backup: Completed with serious errors, Exit code: 16"
            }
            default {                
                Write-Log -logFileName "backup_log.txt" -message "Backup completed with some issues. Exit code: $($robocopyProcess.ExitCode)" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Backup completed with some issues. Exit code: $($robocopyProcess.ExitCode)"
                return "Robocopy Backup: Completed with issues, Exit code: $($robocopyProcess.ExitCode)"
            }
        }
    }
    catch {
        # Enhanced logging for troubleshooting
        $errorDetails = $_.Exception | Out-String       
        Write-Log -logFileName "backup_error_log.txt" -message "Backup failed: $errorDetails" -functionName $MyInvocation.MyCommand.Name
        Catcher -taskName "Backup" -errorMessage $_.Exception.Message
        Show-Error "Robocopy Backup: Failed due to an unexpected error. Please check the log for more information."
        return "Robocopy Backup: Failed due to an unexpected error. Please check the log for more information."
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
    try {
        # DISM CheckHealth
        Start-Process -FilePath 'dism.exe' -ArgumentList '/Online', '/Cleanup-Image', '/CheckHealth' -NoNewWindow -Wait
        if ($LASTEXITCODE -ne 0) {            
            Write-Log -logFileName "repair_error_log.txt" -message "System image health check detected issues." -functionName $MyInvocation.MyCommand.Name
            # DISM ScanHealth
            Start-Process -FilePath 'dism.exe' -ArgumentList '/Online', '/Cleanup-Image', '/ScanHealth' -NoNewWindow -Wait
            if ($LASTEXITCODE -ne 0) {
                Show-Message "System scan detected issues. Attempting to repair..."
                Write-Log -logFileName "repair_error_log.txt" -message "System scan detected issues." -functionName $MyInvocation.MyCommand.Name
                Start-Process -FilePath 'dism.exe' -ArgumentList '/Online', '/Cleanup-Image', '/RestoreHealth' -NoNewWindow -Wait
                if ($LASTEXITCODE -ne 0) {                
                    Write-Log -logFileName "repair_error_log.txt" -message "Failed to repair system issues." -functionName $MyInvocation.MyCommand.Name
                    Show-Message "Failed to repair system issues. Aborting further operations."
                    return "Repair tasks aborted due to failure in system repair."
                }
            }
        }       

        # DISM StartComponentCleanup
        Start-Process -FilePath 'dism.exe' -ArgumentList '/Online', '/Cleanup-Image', '/StartComponentCleanup' -NoNewWindow -Wait
        if ($LASTEXITCODE -ne 0) {            
            Write-Log -logFileName "repair_error_log.txt" -message "Component cleanup failed." -functionName $MyInvocation.MyCommand.Name
            Show-Message "Repair tasks completed with issues during component cleanup."
            return "Repair tasks completed with issues during component cleanup."
        }

        Show-Message "Running System File Checker to scan and repair protected system files..."
        try {
            $sfcProcess = Start-Process -FilePath "sfc" -ArgumentList "/SCANNOW" -NoNewWindow -Wait -PassThru
            if ($sfcProcess.ExitCode -eq 0) {
                Show-Message "System File Checker has completed successfully."
                return "System File Checker has completed successfully."
            }
            else {               
                Write-Log -logFileName "sfc_error_log.txt" -message "SFC finished with issues. Exit code: $($sfcProcess.ExitCode)" -functionName $MyInvocation.MyCommand.Name
                Show-Message "SFC finished with issues. Exit code: $($sfcProcess.ExitCode)"
                return "System File Checker finished with warnings/errors. Exit code: $($sfcProcess.ExitCode)"
            }
        }
        catch {
            $errorDetails = $_.Exception | Out-String            
            Catcher -taskName "Repair Tasks" -errorMessage $errorDetails
            Write-Log -logFileName "sfc_error_log.txt" -message "System File Checker failed: $errorDetails" -functionName $MyInvocation.MyCommand.Name
            Show-Error "System File Checker failed. Please check the log file for more details."
            return "System File Checker failed. Please check the log file for more details."
        }
    }
    catch {
        $errorDetails = $_.Exception | Out-String        
        Write-Log -logFileName "repair_error_log.txt" -message "Repair tasks failed: $errorDetails" -functionName $MyInvocation.MyCommand.Name
        Catcher -taskName "Repair Tasks" -errorMessage $_.Exception.Message
        Show-Error "Repair tasks failed. Please check the log file for more details."
        return "Repair tasks failed. Please check the log file for more details."
    }
}

# Function to install and update WinGet
#
# Function: Start-WinGetUpdate
# Description: This function installs WinGet if it is not already installed or if the installed version is outdated.
#              It downloads necessary dependencies to ensure functionality.
#              If WinGet is already installed and up to date, it proceeds to update all packages using WinGet.
#              Each step includes detailed error handling and logging to help diagnose any issues.
# Usage:
#   Start-WinGetUpdate
function Start-WinGetUpdate {
    Show-Message "Starting Winget Update"
    try {
        # Attempt to run WinGet
        Show-Message "Checking for WinGet installation..."
        Start-Process -FilePath "winget" -ArgumentList "--version" -NoNewWindow -Wait -PassThru -ErrorAction Stop
    }
    catch {
        # If WinGet is not installed, notify the user
        Show-Error "WinGet is not installed on this system. Please install WinGet to continue."
        Catcher -taskName "Start-WinGetUpdate" -errorMessage $_.Exception.Message
        Write-Log -logFileName "winget_update.txt" -message "WinGet is not installed on this system." -functionName $MyInvocation.MyCommand.Name
        return "WinGet is not installed on this system."
    }

    # Run WinGet update to update all installed packages
    try {      
        Show-Message "Running winget update to update all installed packages..."
        $wingetProcess = Start-Process -FilePath "winget" -ArgumentList "update --all --include-unknown --accept-source-agreements --ignore-warnings --disable-interactivity --verbose-logs" -NoNewWindow -Wait -PassThru -ErrorAction Stop
        if ($wingetProcess.ExitCode -ne 0) {
            throw "winget update process failed with exit code $($wingetProcess.ExitCode)."
        }
        Write-Log -logFileName "winget_update.txt" -message "winget update completed successfully." -functionName $MyInvocation.MyCommand.Name  
        Show-Message "Winget update completed successfully."
        return "Winget update completed successfully."
    }
    catch {
        # Log the error message if the WinGet update process fails
        $errorDetails = $_.Exception | Out-String
        Catcher -taskName "Start-WinGetUpdate" -errorMessage $_.Exception.Message
        Write-Log -logFileName "winget_update_error_log.txt" -message "winget update failed: $errorDetails" -functionName $MyInvocation.MyCommand.Name
        Show-Error "Winget update failed. Please check the log file for more details."
        return "Winget update failed. Please check the log file for more details."
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
        Show-Message "Starting System Cleanup..."
        # Run advanced disk cleanup using Windows Clean Manager
        Write-Log -logFileName "cleanup_log.txt" -message "Running advanced disk cleanup with preconfigured options..." -functionName $MyInvocation.MyCommand.Name
        try {
            # Start the Clean Manager tool with the specified options
            Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1"            

            # Wait for the cleanup processes to complete
            Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue | Wait-Process

            Write-Log -logFileName "cleanup_log.txt" -message "Advanced disk cleanup complete." -functionName $MyInvocation.MyCommand.Name
            Show-Message "System Cleanup Completed..."
            return "Advanced disk cleanup complete."    
        }
        catch {
            # Log the error if advanced disk cleanup fails
            Catcher -taskName "Start-Cleanup" -errorMessage $_.Exception.Message
            Write-Log -logFileName "cleanup_log.txt" -message "Advanced disk cleanup failed: $_" -functionName $MyInvocation.MyCommand.Name
            Show-Error "System Cleanup Failed..."
            return "Advanced disk cleanup failed: $_"
        }
    }
    catch {
        # Catch any unexpected errors during the cleanup process
        Catcher -taskName "Start-Cleanup" -errorMessage $_.Exception.Message
        Write-Log -logFileName "cleanup_log.txt" -message "Cleanup tasks failed: $_" -functionName $MyInvocation.MyCommand.Name
        Show-Error "System Cleanup Failed..."
        return "Cleanup tasks failed: $_"
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
        Write-Log -logFileName "drive_optimization_log.txt" -message "Starting drive optimization process." -functionName $MyInvocation.MyCommand.Name
        try {
            # Get the physical disks and filter to only those with known MediaType
            $disks = Get-PhysicalDisk | Where-Object { $_.MediaType -ne "Unspecified" }
            
            # Handle the case where no disks are found
            if ($disks.Count -eq 0) {
                Write-Output "No physical disks found for optimization. Exiting."
                Write-Log -logFileName "drive_optimization_log.txt" -message "No physical disks found for optimization. Exiting." -functionName $MyInvocation.MyCommand.Name
                return "No physical disks found for optimization. Exiting."
            }

            foreach ($disk in $disks) {
                # Get the appropriate partition - filter to only the primary partition
                $partition = Get-Partition -DiskNumber $disk.DeviceId | Where-Object { $_.Type -eq 'Basic' -and $_.IsBoot -eq $true }
                if ($null -ne $partition -and $partition.AccessPaths.Count -gt 0) {
                    # If the MediaType is SSD, run an Optimize-Volume with the Trim option
                    if ($disk.MediaType -eq "SSD") {
                        Write-Output "Running TRIM on SSD: $($disk.FriendlyName)"
                        Write-Log -logFileName "drive_optimization_log.txt" -message "Running TRIM on SSD: $($disk.FriendlyName)" -functionName $MyInvocation.MyCommand.Name
                        try {
                            Optimize-Volume -DriveLetter $partition.DriveLetter -ReTrim -Verbose
                            Write-Log -logFileName "drive_optimization_log.txt" -message "Successfully optimized SSD: $($disk.FriendlyName)" -functionName $MyInvocation.MyCommand.Name
                        }
                        catch {
                            Show-Error "Failed to optimize SSD: $($disk.FriendlyName). Error: $_"
                            Write-Log -logFileName "drive_optimization_log.txt" -message "Failed to optimize SSD: $($disk.FriendlyName). Error: $_" -functionName $MyInvocation.MyCommand.Name
                            Catcher -taskName "SSD Optimization" -errorMessage $_.Exception.Message
                        }
                    }
                    # If the MediaType is HDD, run a defragmentation operation
                    elseif ($disk.MediaType -eq "HDD") {
                        Write-Output "Running Defrag on HDD: $($disk.FriendlyName)"
                        Write-Log -logFileName "drive_optimization_log.txt" -message "Running Defrag on HDD: $($disk.FriendlyName)"
                        try {
                            Optimize-Volume -DriveLetter $partition.DriveLetter -Defrag -Verbose
                            Write-Log -logFileName "drive_optimization_log.txt" -message "Successfully defragmented HDD: $($disk.FriendlyName)" -functionName $MyInvocation.MyCommand.Name
                        }
                        catch {
                            Show-Error "Failed to defragment HDD: $($disk.FriendlyName). Error: $_"
                            Write-Log -logFileName "drive_optimization_log.txt" -message "Failed to defragment HDD: $($disk.FriendlyName). Error: $_" -functionName $MyInvocation.MyCommand.Name
                            Catcher -taskName "HDD Defragmentation" -errorMessage $_.Exception.Message
                        }
                    }
                }
                else {
                    # Log additional context information for skipped disks
                    $reason = "Disk is either unmounted or inaccessible."
                    Write-Output "Skipping optimization on unmounted or inaccessible disk: $($disk.FriendlyName). Reason: $reason"
                    Write-Log -logFileName "drive_optimization_log.txt" -message "Skipped disk: $($disk.FriendlyName). Reason: $reason" -functionName $MyInvocation.MyCommand.Name
                }
            }
            return "Optimization Completed. Exiting."
        }
        catch {
            Catcher -taskName "Drive Optimization" -errorMessage $_.Exception.Message
            Write-Log -logFileName "drive_optimization_log.txt" -message "Drive optimization failed: $_" -functionName $MyInvocation.MyCommand.Name
            return "Drive Optimization: Failed with error $_"
        }
    }
    catch {
        Catcher -taskName "Drive Optimization" -errorMessage $_.Exception.Message
        Write-Log -logFileName "drive_optimization_log.txt" -message "Drive optimization process encountered an unexpected error: $_" -functionName $MyInvocation.MyCommand.Name
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
    # Log and display Basic system information
    $basicInfo = Get-ComputerInfo | Select-Object CSName, WindowsVersion, OSArchitecture, WindowsBuildLabEx
    $basicInfo | ForEach-Object {
        $_ | Format-List | Out-String | ForEach-Object {
            Write-Host $_ -ForegroundColor White
            Write-Log -logFileName "SystemInfoLog" -message "BasicSystemInfo: $_" -functionName "Get-ComputerInfo"
        }
    }

    Write-Host "`n"

    Show-Message "🔥 CPU Information 🔥" -ForegroundColor Yellow -BackgroundColor DarkGreen
    # Log and display CPU information
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
    $cpuInfo | ForEach-Object {
        $_ | Format-List | Out-String | ForEach-Object {
            Write-Host $_ -ForegroundColor Yellow
            Write-Log -logFileName "SystemInfoLog" -message "CPUInfo: $_" -functionName "Get-CimInstance (CPU)"
        }
    }

    Write-Host "`n"

    Show-Message "🌱 Memory Information 🌱" -ForegroundColor Green -BackgroundColor DarkYellow
    # Log and display Memory information
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object Manufacturer, Capacity, Speed, MemoryType
    $memoryInfo | ForEach-Object {
        $_ | Format-List | Out-String | ForEach-Object {
            Write-Host $_ -ForegroundColor Green
            Write-Log -logFileName "SystemInfoLog" -message "MemoryInfo: $_" -functionName "Get-CimInstance (Memory)"
        }
    }

    Write-Host "`n"

    Show-Message "💾 Disk Information 💾" -ForegroundColor Cyan -BackgroundColor DarkRed
    # Log and display Disk information
    $diskInfo = Get-CimInstance -ClassName Win32_DiskDrive | Select-Object DeviceID, Model, Size
    $diskInfo | ForEach-Object {
        $_ | Format-List | Out-String | ForEach-Object {
            Write-Host $_ -ForegroundColor Cyan
            Write-Log -logFileName "SystemInfoLog" -message "DiskInfo: $_" -functionName "Get-CimInstance (Disk)"
        }
    }

    Write-Host "`n"

    Show-Message "🌐 Network Adapter Information 🌐" -ForegroundColor Gray -BackgroundColor DarkMagenta
    # Log and display Network adapter information
    $networkInfo = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object Name, MACAddress, LinkSpeed
    $networkInfo | ForEach-Object {
        $_ | Format-List | Out-String | ForEach-Object {
            Write-Host $_ -ForegroundColor Gray
            Write-Log -logFileName "SystemInfoLog" -message "NetworkInfo: $_" -functionName "Get-NetAdapter (Network)"
        }
    }

    Write-Host "`n"

    Show-Message "🖥️ OS Details 🖥️" -ForegroundColor White -BackgroundColor DarkGreen
    # Log and display Operating system details
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $osInfo | ForEach-Object {
        $_ | Format-List | Out-String | ForEach-Object {
            Write-Host $_ -ForegroundColor White
            Write-Log -logFileName "SystemInfoLog" -message "OSInfo: $_" -functionName "Get-CimInstance (OS)"
        }
    }

    Write-Host "`n"

    Show-Message "📜 BIOS Information 📜" -ForegroundColor Yellow -BackgroundColor DarkCyan
    # Log and display BIOS information
    $biosInfo = Get-CimInstance -ClassName Win32_BIOS
    $biosInfo | ForEach-Object {
        $_ | Format-List | Out-String | ForEach-Object {
            Write-Host $_ -ForegroundColor Yellow
            Write-Log -logFileName "SystemInfoLog" -message "BIOSInfo: $_" -functionName "Get-CimInstance (BIOS)"
        }
    }

    Write-Host "`n"

    Show-Message "🎨 GPU Information 🎨" -ForegroundColor Blue -BackgroundColor DarkYellow
    # Log and display GPU information
    $gpuInfo = Get-CimInstance -ClassName Win32_VideoController
    $gpuInfo | ForEach-Object {
        $_ | Format-List | Out-String | ForEach-Object {
            Write-Host $_ -ForegroundColor Blue
            Write-Log -logFileName "SystemInfoLog" -message "GPUInfo: $_" -functionName "Get-CimInstance (GPU)"
        }
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

# Function: Start-EventLogAnalysis
# Description: This function analyzes system event logs for errors and warnings.
#              It extracts relevant events from the System and Application logs, 
#              and provides a summary report to the user with visually enhanced output.
# Usage:
#   Start-EventLogAnalysis
function Start-EventLogAnalysis {
    Show-Message "🚀 Analyzing Event Logs... Please wait..."
    try {
        $systemLogCritical = @()
        try {
            $systemLogCritical = Get-WinEvent -LogName System -FilterXPath "*[System/Level=1]" -MaxEvents 10 | ForEach-Object {
                [PSCustomObject]@{
                    TimeCreated  = $_.TimeCreated
                    ProviderName = $_.ProviderName
                    Id           = $_.Id
                    Message      = $_.Message                
                }
            }
        }
        catch {
            Write-Log -logFileName "event_log_analysis" -message "No critical events found: $_" -functionName "Start-EventLogAnalysis"
        }

        $systemLogErrors = @()
        try {
            $systemLogErrors = Get-WinEvent -LogName System -FilterXPath "*[System/Level=2]" -MaxEvents 10 | ForEach-Object {
                [PSCustomObject]@{
                    TimeCreated  = $_.TimeCreated
                    ProviderName = $_.ProviderName
                    Id           = $_.Id
                    Message      = $_.Message                
                }
            }
        }
        catch {
            Write-Log -logFileName "event_log_analysis" -message "No error events found: $_" -functionName "Start-EventLogAnalysis"
        }

        if ($systemLogCritical.Count -gt 0) {
            Show-Message "🚨 System Log Critical Events (Last 10) 🚨"
            $systemLogCritical | ForEach-Object {
                Write-Host "============================================================" -ForegroundColor Red
                Write-Host "🕒 Time Created: $($_.TimeCreated)" -ForegroundColor Cyan
                Write-Host "🔌 Provider: $($_.ProviderName)" -ForegroundColor Cyan
                Write-Host "🆔 Id: $($_.Id)" -ForegroundColor Cyan
                Write-Host "💬 Message: $($_.Message)" -ForegroundColor Cyan
                $onlineInfo = Search-OnlineForInfo -message $($_.Message)
                Write-Host "🌐 Mitigation Info: $onlineInfo" -ForegroundColor Green
                Write-Log -logFileName "event_log_analysis" -message "SystemLogCritical: TimeCreated: $($_.TimeCreated) - Provider: $($_.ProviderName) - Id: $($_.Id) - Message: $($_.Message)" -functionName "Start-EventLogAnalysis"
            }
        } else {
            Show-Message "No critical events found."
        }

        if ($systemLogErrors.Count -gt 0) {
            Show-Message "🔥 System Log Errors (Last 10) 🔥"
            $systemLogErrors | ForEach-Object {
                Write-Host "============================================================" -ForegroundColor Magenta
                Write-Host "🕒 Time Created: $($_.TimeCreated)" -ForegroundColor Cyan
                Write-Host "🔌 Provider: $($_.ProviderName)" -ForegroundColor Cyan
                Write-Host "🆔 Id: $($_.Id)" -ForegroundColor Cyan
                Write-Host "💬 Message: $($_.Message)" -ForegroundColor Cyan
                $onlineInfo = Search-OnlineForInfo -message $($_.Message)
                Write-Host "🌐 Mitigation Info: $onlineInfo" -ForegroundColor Green
                Write-Log -logFileName "event_log_analysis" -message "SystemLogError: TimeCreated: $($_.TimeCreated) - Provider: $($_.ProviderName) - Id: $($_.Id) - Message: $($_.Message)" -functionName "Start-EventLogAnalysis"
            }
        } else {
            Show-Message "No error events found."
        }
    }
    catch {
        $errorDetails = $_.Exception | Out-String
        Write-Log -logFileName "event_log_analysis" -message "❌ Event log analysis failed: $errorDetails" -functionName "Start-EventLogAnalysis"
        Catcher -taskName "Event Log Analysis" -errorMessage $_.Exception.Message
        Show-Error "❌ Event log analysis failed. Please check the log file for more details."
    }
}

Clear-Host

# Display the ASCII dragon
Show-Dragon

Write-Host "`n"

# Display the disclaimer using Show-Message
Show-Message "Disclaimer: You are running this script at your own risk."
Write-Host "`n"
$confirmation = Read-Host "Please type 'Y' to confirm: "
if ($confirmation -ne 'Y') {
    Show-Error "User did not confirm. Exiting script."
    exit
}

# Main script loop
do {    
    #Reset
    $global:ErrorRecords = @()
    $operationStatus = @()

    $choice = Show-Menu

    switch ($choice) {
        "1" {
            Clear-Host
            Write-Host "Mirror Backup selected."
            $paths = Get-BackupPaths
            $source = $paths[0]
            $destination = $paths[1]
            Write-Host "Perform Pre-Backup Tasks"
            # Run a quick virus scan
            Start-DefenderScan
            $operationStatus += Start-Backup -source $source -destination $destination
        }
        "2" {
            Clear-Host
            Write-Host "Repair tasks selected."
            Write-Host "Perform Pre-Repair Tasks"
            # Run a quick virus scan
            Start-DefenderScan
            $operationStatus += Start-Repair
        }
        "3" {
            Clear-Host
            Write-Host "Update Apps tasks selected."
            Write-Host "Perform Pre-UpdateApps Tasks"
            # Run a quick virus scan
            Start-DefenderScan
            $operationStatus += Start-WinGetUpdate
        }
        "4" {
            Clear-Host
            Write-Host "Cleanup tasks selected."
            Write-Host "Perform Pre-Cleanup Tasks"
            # Run a quick virus scan
            Start-DefenderScan
            $operationStatus += Start-Cleanup
        }
        "5" {
            Clear-Host
            Write-Host "Drive optimization selected."
            Write-Host "Perform Pre-Optimization Tasks"
            # Run a quick virus scan
            Start-DefenderScan
            $operationStatus += Start-Optimization
        }
        "6" {
            Clear-Host
            Write-Host "Getting Computer Information"
            Start-PCInfo          
        }
        "7" {
            Clear-Host
            Write-Host "Analyzing Event Logs..."
            Start-EventLogAnalysis      
        }
        "8" {
            Clear-Host
            Write-Host "Performing all tasks (Except Mirror Backup)."    
            Write-Host "Perform Pre-Operation Tasks"
            # Run a quick virus scan
            Start-DefenderScan        
            $operationStatus += Start-Repair
            $operationStatus += Start-WinGetUpdate
            $operationStatus += Start-Cleanup
            $operationStatus += Start-Optimization
            Start-PCInfo   
            Start-EventLogAnalysis
        }
        "9" {
            Clear-Host
            Write-Host "Performing all tasks."
            Write-Host "Perform Pre-Operation Tasks"
            # Run a quick virus scan
            Start-DefenderScan 
            $paths = Get-BackupPaths
            $source = $paths[0]
            $destination = $paths[1]
            $operationStatus += Start-Backup -source $source -destination $destination
            $operationStatus += Start-Repair
            $operationStatus += Start-WinGetUpdate
            $operationStatus += Start-Cleanup
            $operationStatus += Start-Optimization
            Start-PCInfo   
            Start-EventLogAnalysis
        }
        "10" {
            Write-Host "Exiting script."
            Clear-Host
            exit
        }
        default {
            Clear-Host
            Write-Host "Invalid selection. Please choose an option from the menu."
        }
    }

    Write-Host "`n"

    # Display a summary message indicating that all tasks are complete.
    if ($operationStatus) {
        Show-Message "All tasks complete! Here is a summary of all operations:"
        Write-Host "`n"
        foreach ($status in $operationStatus) {
            if (-not ($status -is [int]) -and -not ($status -is [System.Int64])) {
                Show-Message $status
            }
        }
    }

    # Display error messages if any error records exist.
    if ($global:ErrorRecords.Count -gt 0) {
        Show-Message "Here is a summary of any errors:"
        Write-Host "`n"
        foreach ($err in $global:ErrorRecords) {
            if (-not ($status -is [int]) -and -not ($status -is [System.Int64])) {
                Show-Error $err
            }
        }
    }

    Write-Host "`n"

    Pause

} while ($true)