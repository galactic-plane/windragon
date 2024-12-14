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
        $robocopyProcess = Start-Process -FilePath "robocopy" -ArgumentList "${source} ${destination} /MIR /FFT /Z /XA:H /W:5 /A-:SH" -NoNewWindow -Wait -PassThru
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
            3 {                
                Write-Log -logFileName "backup_log" -message "Some files were copied and extra files were detected. Exit code: 3" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Some files were copied and extra files were detected. Exit code: 3"
                return "Robocopy Backup: Completed with some issues, Exit code: 3"
            }
            5 {               
                Write-Log -logFileName "backup_log" -message "Some files were mismatched. No files were copied. Exit code: 5" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Some files were mismatched. No files were copied. Exit code: 5"
                return "Robocopy Backup: Completed with mismatched files, Exit code: 5"
            }
            6 {                
                Write-Log -logFileName "backup_log" -message "Additional files or directories were detected and mismatched. Exit code: 6" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Additional files or directories were detected and mismatched. Exit code: 6"
                return "Robocopy Backup: Completed with mismatched files and extra files, Exit code: 6"
            }
            7 {                
                Write-Log -logFileName "backup_log" -message "Files were copied, mismatched, and extra files were detected. Exit code: 7" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Files were copied, mismatched, and extra files were detected. Exit code: 7"
                return "Robocopy Backup: Completed with several issues, Exit code: 7"
            }
            8 {               
                Write-Log -logFileName "backup_log" -message "Backup completed with some files/directories mismatch. Exit code: 8" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Backup completed with some files/directories mismatch. Exit code: 8"
                return "Robocopy Backup: Completed with issues, Exit code: 8"
            }
            16 {                
                Write-Log -logFileName "backup_log" -message "Backup completed with serious errors. Exit code: 16" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Backup completed with serious errors. Exit code: 16"
                return "Robocopy Backup: Completed with serious errors, Exit code: 16"
            }
            default {                
                Write-Log -logFileName "backup_log" -message "Backup completed with some issues. Exit code: $($robocopyProcess.ExitCode)" -functionName $MyInvocation.MyCommand.Name
                Show-Message "Backup completed with some issues. Exit code: $($robocopyProcess.ExitCode)"
                return "Robocopy Backup: Completed with issues, Exit code: $($robocopyProcess.ExitCode)"
            }
        }
    }
    catch {
        # Enhanced logging for troubleshooting
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

    if ($sources.Count -ne $destinations.Count) {
        Write-Host "Error: The number of sources and destinations must match."
        return
    }

    for ($i = 0; $i -lt $sources.Count; $i++) {
        $source = $sources[$i]
        $destination = $destinations[$i]

        Write-Host "Starting backup for Source: $source -> Destination: $destination"
        Start-Backup -source $source -destination $destination
    }
}