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
# 3. Run the script by typing: `\.\WinDragon.ps1`
# 4. Follow the interactive prompts to select the tasks you wish to perform.

# Script Options and Corresponding Parameters

# 1. Mirror Backup
# Command: .\WinDragon.ps1 -RunChoice 1

# 2. Repair Tasks (DISM and SFC)
# Command: .\WinDragon.ps1 -RunChoice 2

# 3. Update Installed Software
# Command: .\WinDragon.ps1 -RunChoice 3

# 4. Cleanup Tasks
# Command: .\WinDragon.ps1 -RunChoice 4

# 5. Drive Optimization
# Command: .\WinDragon.ps1 -RunChoice 5

# 6. Get System Information
# Command: .\WinDragon.ps1 -RunChoice 6

# 7. Analyze Event Logs
# Command: .\WinDragon.ps1 -RunChoice 7

# 8. Perform All Tasks (Except Mirror Backup)
# Command: .\WinDragon.ps1 -RunChoice 8

# 9. Perform All Tasks (Including Mirror Backup)
# Command: .\WinDragon.ps1 -RunChoice 9

# 10. Exit
# This option is not applicable when using parameters.

# Examples

# Run Repair Tasks:
# .\WinDragon.ps1 -RunChoice 2

# Perform All Tasks Including Mirror Backup:
# .\WinDragon.ps1 -RunChoice 9

# Get System Information:
# .\WinDragon.ps1 -RunChoice 6

# Notes:
# - Use these commands directly for automation or scheduling.
# - Ensure PowerShell is run with administrative privileges.

# Requirements:
# - PowerShell 7.4.6 or newer
# - Administrator privileges to perform system-level operations like repair, cleanup, and optimization.

param (
    [int]$RunChoice
)

# Function to ensure script is running with admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as an administrator. Please restart PowerShell with elevated privileges." -ForegroundColor Red
    exit
}

# Global variable for storing error records
$global:ErrorRecords = @()
# Global variable to ensure the quick scan runs only once
$global:QuickScanRunOnce = $false
# Global variable to ensure the maintenance scan runs only once
$global:MaintenanceScanRunOnce = $false

#####################################
# Import the Utils Module
. .\Modules\Utils.ps1
#####################################
# Utility functions for various common tasks:
# - Initialize-Settings: Creates a settings file for default paths.
# - Catcher: Handles errors by throwing an exception if the task name is null or empty.
# - Write-Log: Logs messages to a log file in a dated folder.
# - Start-DefenderScan: Runs a virus scan using Windows Defender based on the current status.

#####################################
# Import the Backup Module
. .\Modules\Backup.ps1
#####################################
# Functions for backup operations:
# - Get-BackupPaths: Prompts the user to enter the source and destination directories for a backup operation.
# - Invoke-All-Backups: Initiates a backup operation using Robocopy to copy files from the source directory to a destination directory from settings file.

#####################################
# Import the Repair Module
. .\Modules\Repair.ps1
#####################################
# Functions for system repair tasks:
# - Start-Repair: Performs a series of system repair tasks using various system tools (e.g., DISM and SFC).

#####################################
# Import the Update Module
. .\Modules\Update.ps1
#####################################
# Functions for updating installed software:
# - Update-AllPackages: Installs WinGet if it is not already installed or if the installed version is outdated, and updates all installed packages.

#####################################
# Import the Cleanup Module
. .\Modules\Cleanup.ps1
#####################################
# Functions for system cleanup tasks:
# - Start-Cleanup: Executes an advanced disk cleanup using the built-in Windows tool.

#####################################
# Import the Optimize Module
. .\Modules\Optimize.ps1
#####################################
# Functions for disk optimization:
# - Start-Optimization: Performs disk optimization on all physical drives detected by the system.

#####################################
# Import the SysInfo Module
. .\Modules\SysInfo.ps1
#####################################
# Functions for collecting system information:
# - Start-PCInfo: Collects and displays detailed information about the computer's hardware and system configuration.

#####################################
# Import the SysEvents Module
. .\Modules\SysEvents.ps1
#####################################
# Functions for event log analysis:
# - Search-OnlineForInfo: Takes a message string and generates a Bing search URL for the given information.
# - Get-EventLogEntries: Retrieves event log entries based on the specified log name and event level.
# - Show-EventLogEntries: Displays event log entries with detailed information and logs the analysis.
# - Start-EventLogAnalysis: Analyzes the system event logs for critical events and errors.
#####################################

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
    Write-Host $dragon -ForegroundColor Red
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
        $border = '█' * ($message.Length)
        Write-Host "┌$border┐" -ForegroundColor White
        Write-Host " $message " -ForegroundColor White
        Write-Host "└$border┘" -ForegroundColor White
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
        $border = '█' * ($message.Length)
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
                { Show-AliveProgressSim -PercentComplete 100 -Message "Mirror Backup selected..." -Symbol "█" },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Perform Pre-Backup Tasks..." -Symbol "█" },
                { Start-DefenderScan -ScanType QuickScan },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Performing Mirror Backup...." -Symbol "█" },
                { $operationStatus += Invoke-All-Backups -settings $settings },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Mirror Backup Complete...." -Symbol "█" }
            )
        }
        "2" {
            $tasks = @(
                { Show-AliveProgressSim -PercentComplete 100 -Message "Repair tasks selected..." -Symbol "█" },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Perform Pre-Repair Tasks..." -Symbol "█" },
                { Start-DefenderScan -ScanType QuickScan },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Starting Windows Maintenance..." -Symbol "█" },
                { Start-WindowsMaintenance },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Executing Repair..." -Symbol "█" },
                { $operationStatus += Start-Repair },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Repair Completed." -Symbol "█" }
            )
        }
        "3" {
            $tasks = @(
                { Show-AliveProgressSim -PercentComplete 100 -Message "Update Apps tasks selected..." -Symbol "█" },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Perform Pre-UpdateApps Tasks..." -Symbol "█" },
                { Start-DefenderScan -ScanType QuickScan },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Starting Windows Maintenance..." -Symbol "█" },
                { Start-WindowsMaintenance },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Updating Apps..." -Symbol "█" },
                { $operationStatus += Update-AllPackages },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Update Completed." -Symbol "█" }
            )
        }
        "4" {
            $tasks = @(
                { Show-AliveProgressSim -PercentComplete 100 -Message "Cleanup tasks selected..." -Symbol "█" },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Perform Pre-Cleanup Tasks..." -Symbol "█" },
                { Start-DefenderScan -ScanType QuickScan },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Starting Windows Maintenance..." -Symbol "█" },
                { Start-WindowsMaintenance },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Cleaning up..." -Symbol "█" },
                { $operationStatus += Start-Cleanup },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Cleanup Completed." -Symbol "█" }
            )
        }
        "5" {
            $tasks = @(
                { Show-AliveProgressSim -PercentComplete 100 -Message "Drive optimization selected..." -Symbol "█" },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Perform Pre-Optimization Tasks..." -Symbol "█" },
                { Start-DefenderScan -ScanType QuickScan },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Starting Windows Maintenance..." -Symbol "█" },
                { Start-WindowsMaintenance },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Optimizing Drives..." -Symbol "█" },
                { $operationStatus += Start-Optimization },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Optimization Completed." -Symbol "█" }
            )
        }
        "6" {
            $tasks = @(                
                { Show-AliveProgressSim -PercentComplete 100 -Message "Getting Computer Information..." -Symbol "█" },
                { Start-PCInfo },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Information Retrieved." -Symbol "█" }
            )
        }
        "7" {
            $tasks = @(                
                { Show-AliveProgressSim -PercentComplete 100 -Message "Analyzing Event Logs..." -Symbol "█" },
                { Start-EventLogAnalysis },
                { Show-AliveProgressSim -PercentComplete 100 -Message "Event Log Analysis Completed." -Symbol "█" }
            )
        }
        "8" {
            $tasks = @(                
                { Show-AliveProgressSim -PercentComplete 100 -Message "Performing all tasks (Except Mirror Backup)..." -Symbol "█" },
                { Start-DefenderScan -ScanType QuickScan },
                { Start-WindowsMaintenance },
                { $operationStatus += Start-Repair },
                { $operationStatus += Update-AllPackages },
                { $operationStatus += Start-Cleanup },
                { $operationStatus += Start-Optimization },
                { Start-PCInfo },
                { Start-EventLogAnalysis },
                { Show-AliveProgressSim -PercentComplete 100 -Message "All Selected Tasks Completed." -Symbol "█" }
            )
        }
        "9" {
            $tasks = @(                
                { Show-AliveProgressSim -PercentComplete 100 -Message "Performing all tasks..." -Symbol "█" },
                { Start-DefenderScan -ScanType QuickScan },
                { Start-WindowsMaintenance },
                { Invoke-All-Backups -settings $settings },
                { $operationStatus += Start-Repair },
                { $operationStatus += Update-AllPackages },
                { $operationStatus += Start-Cleanup },
                { $operationStatus += Start-Optimization },
                { Start-PCInfo },
                { Start-EventLogAnalysis },
                { Show-AliveProgressSim -PercentComplete 100 -Message "All Tasks Completed." -Symbol "█" }
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

    # Display the disclaimer using Show-Message
    Show-Message "Disclaimer: You are running this script at your own risk."
    Write-Host "`n"
    $confirmation = Read-Host "Please type 'Y' to confirm: "
    if ($confirmation -ne 'Y') {
        Show-Error "User did not confirm. Exiting script."
        exit
    }

    # Initialize the settings file
    $settings = Initialize-Settings

    # Main script loop
    do {

        $global:StartTime = Get-Date
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