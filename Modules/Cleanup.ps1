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