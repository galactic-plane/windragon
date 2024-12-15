# Function: Update-AllPackages
# Description: Updates all installed packages from various package managers.
# Parameters: None
# Usage: Update-AllPackages
function Update-AllPackages {
    # Helper function for logging
    function Log {
        param([string]$Message)
        Write-Host $Message -ForegroundColor Green
    }

    # Update Winget packages
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Log "Updating Winget packages..."
        try {
            winget upgrade --all --accept-source-agreements --ignore-warnings --disable-interactivity
        } catch {
            Write-Host "Error updating Winget packages: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Winget is not installed." -ForegroundColor Yellow
    }

    # Update Chocolatey packages
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Log "Updating Chocolatey packages..."
        try {
            choco upgrade all -y
        } catch {
            Write-Host "Error updating Chocolatey packages: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Chocolatey is not installed." -ForegroundColor Yellow
    }

    # Update Scoop packages
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Log "Updating Scoop packages..."
        try {
            scoop update
            scoop update *
        } catch {
            Write-Host "Error updating Scoop packages: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Scoop is not installed." -ForegroundColor Yellow
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
            Write-Host "Error updating Pip packages: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Pip is not installed." -ForegroundColor Yellow
    }

    # Update Npm packages
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Log "Updating global npm packages..."
        try {
            npm update -g
        } catch {
            Write-Host "Error updating global npm packages: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Npm is not installed." -ForegroundColor Yellow
    }

    # Update .NET Tools
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        Log "Updating .NET global tools..."
        try {
            dotnet tool update --global --all
        } catch {
            Write-Host "Error updating .NET global tools: $_" -ForegroundColor Red
        }
    } else {
        Write-Host ".NET SDK is not installed." -ForegroundColor Yellow
    }

    # Update PowerShell modules
    if (Get-Command Update-Module -ErrorAction SilentlyContinue) {
        Log "Updating PowerShell modules..."
        try {
            $response = Read-Host "Are you sure you want to update all PowerShell modules? This may affect compatibility. (Y/N)"
            if ($response -eq 'Y') {
                Get-InstalledModule | ForEach-Object {
                    $module = $_.Name
                    Log "Updating PowerShell module: $module"
                    Update-Module -Name $module -Force
                }
            } else {
                Write-Host "Skipping PowerShell module updates." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Error updating PowerShell modules: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "PowerShellGet module is not installed." -ForegroundColor Yellow
    }
}