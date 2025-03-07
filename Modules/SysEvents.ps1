# Function: Search-OnlineForInfo
# Description: This function takes a message string and generates a Bing search URL for the given information.
#              It is used to create online search links for specific hardware properties, such as Name, Manufacturer, Model, etc., for easy online reference.
# Parameters:
#   - $message: The string containing the hardware information to search for.
# Returns: A URL string that points to a Bing search for the provided message.
# Process:
#   1. Checks if the message contains a period and trims it accordingly.
#   2. Constructs a hashtable with parameters for the Bing search query.
#   3. Builds a query string by encoding the parameters.
#   4. Constructs the full request URL.
#   5. Returns the constructed URL.

function Search-OnlineForInfo ($message) {
    $encodedMessage = if ($message -contains '.') { $message.Split('.')[0].Trim('"') } else { $message.Trim('"') }

    # Define parameters as a hashtable
    $parameters = @{
        q    = $encodedMessage
        shm  = "cr"
        form = "DEEPSH"
    }

    # Build the query string by encoding each parameter
    $queryString = ($parameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$([uri]::EscapeDataString($_.Value))" }) -join '&'
    
    # Construct the full request URL directly
    $requestUrl = "https://www.bing.com/search?$queryString"

    return "$requestUrl"
}

# Function: Get-EventLogEntries
# Description: Retrieves event log entries based on the specified log name and event level.
# Parameters:
#   - [string]$logName: The name of the event log to query.
#   - [int]$level: The level of events to filter (e.g., 1 for critical, 2 for error).
#   - [int]$maxEvents: The maximum number of events to retrieve (default is 10).
# Returns: An array of custom objects containing event log details.
# Usage: $entries = Get-EventLogEntries -logName "System" -level 1 -maxEvents 10
function Get-EventLogEntries {
    param (
        [string]$logName,
        [int]$level,
        [int]$maxEvents = 10
    )
    try {      
        
        $events = Get-WinEvent -LogName System -FilterXPath "*[System/Level=$level]" -MaxEvents $maxEvents | ForEach-Object {
            [PSCustomObject]@{
                TimeCreated  = $_.TimeCreated
                ProviderName = $_.ProviderName
                Id           = $_.Id
                Message      = $_.Message                
            }
        }
        
        if ($events) {
            return $events
        }
        else {
            Write-Log -logFileName "event_log_analysis" -message "No events found for level $level in $logName." -functionName "Get-EventLogEntries"
            return @()
        }
    }
    catch {
        Write-Log -logFileName "event_log_analysis_errors" -message "Error querying events for level $level in ${logName}: $_" -functionName "Get-EventLogEntries"
        return @()
    }
}


# Function: Show-EventLogEntries
# Description: Displays event log entries with detailed information and logs the analysis.
# Parameters:
#   - [string]$title: The title to display before showing the event log entries.
#   - [array]$entries: An array of event log entries to display.
#   - [string]$color: The color to use for displaying the event log entries.
# Usage:
#   $entries = Get-EventLogEntries -logName "Application" -level 2 -maxEvents 10
#   Show-EventLogEntries -title "Recent Application Events" -entries $entries -color Yellow
function Show-EventLogEntries {
    param (
        [string]$title,
        [array]$entries,
        [string]$color
    )
    if ($entries.Count -gt 0) {
        Show-Message $title
        $entries | ForEach-Object {
            Write-Host "████████████████████████████████████████████████████" -ForegroundColor $color
            Write-Host "🕒 Time Created: $($_.TimeCreated)" -ForegroundColor Cyan
            Write-Host "🔌 Provider: $($_.ProviderName)" -ForegroundColor Cyan
            Write-Host "🆔 Id: $($_.Id)" -ForegroundColor Cyan
            Write-Host "💬 Message: $($_.Message)" -ForegroundColor Cyan
            $onlineInfo = Search-OnlineForInfo -message $($_.Message)
            Write-Host "🌐 Mitigation Info: $onlineInfo" -ForegroundColor Green
            Write-Log -logFileName "event_log_analysis" -message "${title}: TimeCreated: $($_.TimeCreated) - Provider: $($_.ProviderName) - Id: $($_.Id) - Message: $($_.Message)" -functionName "Show-EventLogEntries"
        }
    }
    else {
        Show-Message "No events found for $title."
    }
}

# Function: Start-EventLogAnalysis
# Description: Analyzes the system event logs for critical events and errors.
#              Retrieves critical and error events from the system event log and displays them.
#              If an error occurs during the analysis, it logs the error details and shows an error message.
# Parameters: None
# Usage: Start-EventLogAnalysis
# Example:
#   Start-EventLogAnalysis
#   This command starts the analysis of the system event logs and displays the critical and error events.
function Start-EventLogAnalysis {
    Show-Message "🚀 Analyzing Event Logs... Please wait..."
    try {
        $systemLogErrors = Get-EventLogEntries -logName "System" -level 2 -maxEvents 10
        Show-EventLogEntries -title "🔥 System Log Errors (Last 10) 🔥" -entries $systemLogErrors -color "Magenta"
    }
    catch {
        $errorDetails = $_.Exception | Out-String
        Write-Log -logFileName "event_log_analysis_errors" -message "❌ Event log analysis failed: $errorDetails" -functionName "Start-EventLogAnalysis"
        Catcher -taskName "Event Log Analysis" -errorMessage $_.Exception.Message
        Show-Error "❌ Event log analysis failed. Please check the log file for more details."
    }
}