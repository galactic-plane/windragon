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
        Show-Message "Checking system health using DISM..."
        Start-Process -FilePath 'dism.exe' -ArgumentList '/Online', '/Cleanup-Image', '/CheckHealth' -NoNewWindow -Wait
        if ($LASTEXITCODE -ne 0) {            
            Write-Log -logFileName "repair_error_log.txt" -message "System image health check detected issues." -functionName $MyInvocation.MyCommand.Name
            # DISM ScanHealth
            Show-Message "System scan detected issues. Attempting to repair..."
            Start-Process -FilePath 'dism.exe' -ArgumentList '/Online', '/Cleanup-Image', '/ScanHealth' -NoNewWindow -Wait
            if ($LASTEXITCODE -ne 0) {
                Write-Log -logFileName "repair_error_log.txt" -message "System scan detected issues." -functionName $MyInvocation.MyCommand.Name
                Start-Process -FilePath 'dism.exe' -ArgumentList '/Online', '/Cleanup-Image', '/RestoreHealth' -NoNewWindow -Wait
                if ($LASTEXITCODE -ne 0) {                
                    Write-Log -logFileName "repair_error_log.txt" -message "Failed to repair system issues." -functionName $MyInvocation.MyCommand.Name
                    Show-Error "Failed to repair system issues. Aborting further operations."
                    return "Repair tasks aborted due to failure in system repair."
                }
            }
        }       

        # DISM StartComponentCleanup
        Show-Message "Running Component Cleanup..."
        Start-Process -FilePath 'dism.exe' -ArgumentList '/Online', '/Cleanup-Image', '/StartComponentCleanup' -NoNewWindow -Wait
        if ($LASTEXITCODE -ne 0) {            
            Write-Log -logFileName "repair_error_log.txt" -message "Component cleanup failed." -functionName $MyInvocation.MyCommand.Name
            Show-Error "Repair tasks completed with issues during component cleanup."
            return "Repair tasks completed with issues during component cleanup."
        }

        # Running System File Checker
        Show-Message "Running System File Checker to scan and repair protected system files..."
        try {
            $sfcProcess = Start-Process -FilePath "sfc" -ArgumentList "/SCANNOW" -NoNewWindow -Wait -PassThru
            if ($sfcProcess.ExitCode -eq 0) {
                Show-Message "System File Checker has completed successfully."
                return "System File Checker has completed successfully."
            }
            else {               
                Write-Log -logFileName "sfc_error_log.txt" -message "SFC finished with issues. Exit code: $($sfcProcess.ExitCode)" -functionName $MyInvocation.MyCommand.Name
                Show-Error "SFC finished with issues. Exit code: $($sfcProcess.ExitCode)"
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