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