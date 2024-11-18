# Function: Start-Optimization
# Description: This function performs disk optimization on all physical drives detected by the system. It distinguishes
#              between SSDs and HDDs, applying the appropriate optimization method for each type.
#              For SSDs, it runs the TRIM command to optimize data storage. For HDDs, it performs defragmentation to
#              improve performance. It also logs each action and any errors encountered during the optimization.
# Parameters: None
# Usage: Start-Optimization
# Steps:
#   1. Get all physical disks and filter to only those with a specified MediaType (e.g., SSD, HDD).
#   2. Skip optimization for any unmounted or inaccessible disks.
#   3. For each detected drive:
#       a. If it is an SSD, run TRIM.
#       b. If it is an HDD, run defragmentation.
#   4. Log each step of the optimization process, including successes, failures, and any skipped drives.

function Start-Optimization {
    try {
        Show-Message "Optimizing drives..."
        Write-Log -logFileName "drive_optimization_log" -message "Starting drive optimization process." -functionName $MyInvocation.MyCommand.Name
        try {
            # Get the volumes to optimize, filtering by specific criteria
            $partitions = Get-Volume | Where-Object { $_.DriveLetter -and -not $_.IsReadOnly -and $_.DriveType -ne 'System' }
            
            # Handle the case where no partitions are found
            if ($partitions.Count -eq 0) {
                Write-Host "No volumes found for optimization. Exiting."
                Write-Log -logFileName "drive_optimization_log" -message "No volumes found for optimization. Exiting." -functionName $MyInvocation.MyCommand.Name
                return "No volumes found for optimization. Exiting."
            }

            foreach ($partition in $partitions) {
                # Get the appropriate disk
                $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq (Get-Partition -DriveLetter $partition.DriveLetter).DiskNumber }
                if ($null -ne $disk) {
                    # If the MediaType is SSD, run an Optimize-Volume with the Trim option
                    if ($disk.MediaType -eq "SSD") {
                        Write-Host "Running TRIM on SSD: $($disk.FriendlyName)"
                        Write-Log -logFileName "drive_optimization_log" -message "Running TRIM on SSD: $($disk.FriendlyName)" -functionName $MyInvocation.MyCommand.Name
                        try {
                            Optimize-Volume -DriveLetter $partition.DriveLetter -ReTrim -Verbose
                            Write-Log -logFileName "drive_optimization_log" -message "Successfully optimized SSD: $($disk.FriendlyName)" -functionName $MyInvocation.MyCommand.Name
                        }
                        catch {
                            Show-Error "Failed to optimize SSD: $($disk.FriendlyName). Error: $_"
                            Write-Log -logFileName "drive_optimization_log_errors" -message "Failed to optimize SSD: $($disk.FriendlyName). Error: $_" -functionName $MyInvocation.MyCommand.Name
                            Catcher -taskName "SSD Optimization" -errorMessage $_.Exception.Message
                        }
                    }
                    # If the MediaType is HDD, run a defragmentation operation
                    elseif ($disk.MediaType -eq "HDD") {
                        Write-Host "Running Defrag on HDD: $($disk.FriendlyName)"
                        Write-Log -logFileName "drive_optimization_log" -message "Running Defrag on HDD: $($disk.FriendlyName)"
                        try {
                            Optimize-Volume -DriveLetter $partition.DriveLetter -Defrag -Verbose
                            Write-Log -logFileName "drive_optimization_log" -message "Successfully defragmented HDD: $($disk.FriendlyName)" -functionName $MyInvocation.MyCommand.Name
                        }
                        catch {
                            Show-Error "Failed to defragment HDD: $($disk.FriendlyName). Error: $_"
                            Write-Log -logFileName "drive_optimization_log_errors" -message "Failed to defragment HDD: $($disk.FriendlyName). Error: $_" -functionName $MyInvocation.MyCommand.Name
                            Catcher -taskName "HDD Defragmentation" -errorMessage $_.Exception.Message
                        }
                    }
                }
                else {
                    # Log additional context information for skipped disks
                    $reason = "Disk is either unmounted or inaccessible."
                    Write-Host "Skipping optimization on unmounted or inaccessible partition: $($partition.DriveLetter). Reason: $reason"
                    Write-Log -logFileName "drive_optimization_log" -message "Skipped partition: $($partition.DriveLetter). Reason: $reason" -functionName $MyInvocation.MyCommand.Name
                }
            }
            return "Optimization Completed. Exiting."
        }
        catch {
            Catcher -taskName "Drive Optimization" -errorMessage $_.Exception.Message
            Write-Log -logFileName "drive_optimization_log_errors" -message "Drive optimization failed: $_" -functionName $MyInvocation.MyCommand.Name
            throw
        }
    }
    catch {
        Catcher -taskName "Drive Optimization" -errorMessage $_.Exception.Message
        Write-Log -logFileName "drive_optimization_log_errors" -message "Drive optimization process encountered an unexpected error: $_" -functionName $MyInvocation.MyCommand.Name
        return "Drive Optimization: Failed with error $_"
    }
}