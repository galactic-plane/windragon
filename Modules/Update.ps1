# Function: Update-AllPackages
# Description: Updates all installed packages from various package managers.
# Parameters: None
# Usage: Update-AllPackages
function Update-AllPackages {
    # Helper function for logging
    function Log {
        param([string]$Message)
        Show-AliveProgressSim -PercentComplete 100 -Message $Message -Symbol "█"
    }

    # Update Winget packages
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Log "Updating Winget packages..."
        try {
            winget upgrade --all --accept-source-agreements --ignore-warnings --disable-interactivity
        } catch {
            Show-Error "Error updating Winget packages: $_"
        }
    } else {
        Show-AliveProgressSim -PercentComplete 100 -Message "Winget is not installed." -Symbol "█"
    }

    # Update Chocolatey packages
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Log "Updating Chocolatey packages..."
        try {
            choco upgrade all -y
        } catch {
            Show-Error "Error updating Chocolatey packages: $_"
        }
    } else {
        Show-AliveProgressSim -PercentComplete 100 -Message "Chocolatey is not installed." -Symbol "█"
    }

    # Update Scoop packages
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Log "Updating Scoop packages..."
        try {
            scoop update
            scoop update *
        } catch {
            Show-Error "Error updating Scoop packages: $_"
        }
    } else {
        Show-AliveProgressSim -PercentComplete 100 -Message "Scoop is not installed." -Symbol "█"
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
            Show-Error "Error updating Pip packages: $_"
        }
    } else {
        Show-AliveProgressSim -PercentComplete 100 -Message "Pip is not installed." -Symbol "█"
    }

    # Update Npm packages
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Log "Updating global npm packages..."
        try {
            npm update -g
        } catch {
            Show-Error "Error updating global npm packages: $_"
        }
    } else {
        Show-AliveProgressSim -PercentComplete 100 -Message "Npm is not installed." -Symbol "█"
    }

    # Update .NET Tools
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        Log "Updating .NET global tools..."
        try {
            dotnet tool update --global --all
        } catch {
            Show-Error "Error updating .NET global tools: $_"
        }
    } else {
        Show-AliveProgressSim -PercentComplete 100 -Message ".NET SDK is not installed." -Symbol "█"
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
            Show-Error "Error updating PowerShell modules: $_"
        }
    } else {
        Show-AliveProgressSim -PercentComplete 100 -Message "PowerShellGet module is not installed." -Symbol "█"
    }
}