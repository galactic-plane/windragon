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
        Show-AliveProgressSim -PercentComplete 100 -Message "Performing all tasks..." -Symbol "█"
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
        Show-AliveProgressSim -PercentComplete 100 -Message "Performing all tasks..." -Symbol "█"
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
                Show-AliveProgressSim -PercentComplete 100 -Message "Performing all tasks..." -Symbol "█"
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