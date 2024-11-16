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
        Write-Log -logFileName "winget_update_errors" -message "WinGet is not installed on this system." -functionName $MyInvocation.MyCommand.Name
        return "WinGet is not installed on this system."
    }

    # Run WinGet update to update all installed packages
    try {      
        Show-Message "Running winget update to update all installed packages..."
        $wingetProcess = Start-Process -FilePath "winget" -ArgumentList "update --all --include-unknown --accept-source-agreements --ignore-warnings --disable-interactivity --verbose-logs" -NoNewWindow -Wait -PassThru -ErrorAction Stop
        if ($wingetProcess.ExitCode -ne 0) {
            throw "winget update process failed with exit code $($wingetProcess.ExitCode)."
        }
        Write-Log -logFileName "winget_update" -message "winget update completed successfully." -functionName $MyInvocation.MyCommand.Name  
        Show-Message "Winget update completed successfully."
        return "Winget update completed successfully."
    }
    catch {
        # Log the error message if the WinGet update process fails
        $errorDetails = $_.Exception | Out-String
        Catcher -taskName "Start-WinGetUpdate" -errorMessage $_.Exception.Message
        Write-Log -logFileName "winget_update_errors" -message "winget update failed: $errorDetails" -functionName $MyInvocation.MyCommand.Name
        Show-Error "Winget update failed. Please check the log file for more details."
        return "Winget update failed. Please check the log file for more details."
    }
}