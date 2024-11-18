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