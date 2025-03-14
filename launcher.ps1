# Define ASCII Art for 'WinDragon'
$asciiArt = @"
 .------..------..------..------.
|P.--. ||R.--. ||O.--. ||G.--. |
| :/\: || :(): || :/\: || :/\: |
| (__) || ()() || :\/: || :\/: |
| '--'P|| '--'R|| '--'O|| '--'G|
`------'`------'`------'`------'
WinDragon GUI vBeta build 2025.03.07.01
"@

# Define the file path for winDragon.ps1
$winDragonScriptPath = "d:/windragon/winDragon.ps1"

# Display ASCII Art in Terminal
Write-Host $asciiArt -ForegroundColor Cyan

# Load GUI Components
Add-Type -AssemblyName PresentationFramework

# Function to Display Status Messages
function Show-StatusMessage {
    param (
        [string]$message
    )
    Write-Host ""
    Write-Host "status: $message" -ForegroundColor Cyan
    Write-Host ""
    $outputTextBox.Text += "`nstatus: $message"
}

# Create Menu
$menu = New-Object System.Windows.Controls.Menu
[System.Windows.Controls.DockPanel]::SetDock($menu, "Top")
$fileMenu = New-Object System.Windows.Controls.MenuItem
$fileMenu.Header = "File"

$exitMenuItem = New-Object System.Windows.Controls.MenuItem
$exitMenuItem.Header = "Exit"
$exitMenuItem.Add_Click({ $window.Close() })

$fileMenu.Items.Add($exitMenuItem) | Out-Null
$menu.Items.Add($fileMenu) | Out-Null

# Create TabControl
$tabControl = New-Object System.Windows.Controls.TabControl
$tabControl.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#060d21")

# Create Maintenance Tab
$maintenanceTab = New-Object System.Windows.Controls.TabItem
$maintenanceTab.Header = "Maintenance"

# Create a New Window
$window = New-Object System.Windows.Window
$window.Title = "WinDragon GUI"
$window.Width = 1024
$window.Height = 768
$window.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#060d21")
$window.WindowStartupLocation = "CenterScreen"

# Create a Grid Layout
$grid = New-Object System.Windows.Controls.Grid

# Define Rows and Columns
for ($i = 0; $i -lt 5; $i++) {
    $rowDef = New-Object System.Windows.Controls.RowDefinition
    $grid.RowDefinitions.Add($rowDef) | Out-Null
}

for ($j = 0; $j -lt 3; $j++) {
    $colDef = New-Object System.Windows.Controls.ColumnDefinition
    $grid.ColumnDefinitions.Add($colDef) | Out-Null
}

# Create Header
$header = New-Object System.Windows.Controls.TextBlock
$header.Text = "WinDragon GUI"
$header.HorizontalAlignment = "Center"
$header.VerticalAlignment = "Center"
$header.FontSize = 18
$header.Foreground = [System.Windows.Media.Brushes]::White
$header.Margin = "0,0,0,5"

$grid.Children.Add($header) | Out-Null
[System.Windows.Controls.Grid]::SetRow($header, 0)
[System.Windows.Controls.Grid]::SetColumnSpan($header, 3)

# Create Footer
$footer = New-Object System.Windows.Controls.TextBlock
$footer.Text = "https://github.com/galactic-plane/windragon"
$footer.HorizontalAlignment = "Center"
$footer.VerticalAlignment = "Center"
$footer.FontSize = 14
$footer.Foreground = [System.Windows.Media.Brushes]::White
$footer.Margin = "0,5,0,0"

$grid.Children.Add($footer) | Out-Null
[System.Windows.Controls.Grid]::SetRow($footer, 4)
[System.Windows.Controls.Grid]::SetColumnSpan($footer, 3)

# Create Output TextBox
$outputTextBox = New-Object System.Windows.Controls.TextBox
$outputTextBox.HorizontalAlignment = "Stretch"
$outputTextBox.VerticalAlignment = "Stretch"
$outputTextBox.FontSize = 12
$outputTextBox.Foreground = [System.Windows.Media.Brushes]::White
$outputTextBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#060d21")
$outputTextBox.Margin = "10"
$outputTextBox.IsReadOnly = $true
$outputTextBox.TextWrapping = "Wrap"
$outputTextBox.VerticalScrollBarVisibility = "Auto"
$outputTextBox.Height = 50;

$grid.Children.Add($outputTextBox) | Out-Null
[System.Windows.Controls.Grid]::SetRow($outputTextBox, 5)
[System.Windows.Controls.Grid]::SetColumnSpan($outputTextBox, 3)

# Update Grid Row Definitions to accommodate TextBox
$rowDef = New-Object System.Windows.Controls.RowDefinition
$rowDef.Height = "Auto"
$grid.RowDefinitions.Add($rowDef) | Out-Null

# Create Buttons
$buttonTitles = @(
    "Repair Tasks",
    "Update Software",
    "Cleanup Tasks",
    "Drive Optimization",
    "System Information",
    "Analyze Logs"
)

# Create Button Style
$buttonStyle = New-Object System.Windows.Style([System.Windows.Controls.Button])
$buttonStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Control]::FontSizeProperty, [double]14)))
$buttonStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Control]::WidthProperty, [double]200)))
$buttonStyle.Setters.Add((New-Object System.Windows.Setter([System.Windows.Controls.Control]::HeightProperty, [double]50)))

# Create Buttons
$index = 0
$buttonTitles | ForEach-Object -Process {
    $button = New-Object System.Windows.Controls.Button
    $button.Content = $_
    $button.Style = $buttonStyle
    $button.Tag = $index  # Ensure the index is correctly stored in the button object

    # Define Button Click Action
    $button.Add_Click({
            param($btnSender, $customEventArgs)
            $buttonIndex = $btnSender.Tag  # Retrieve the correct button index

            $window.Dispatcher.Invoke([action] {
                    try {
                        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
                        switch ($buttonIndex) {
                            0 { Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-File", $winDragonScriptPath, "-RunChoice", "2" -Wait }
                            1 { Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-File", $winDragonScriptPath, "-RunChoice", "3" -Wait }
                            2 { Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-File", $winDragonScriptPath, "-RunChoice", "4" -Wait }
                            3 { Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-File", $winDragonScriptPath, "-RunChoice", "5" -Wait }
                            4 { Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-File", $winDragonScriptPath, "-RunChoice", "6" -Wait }
                            5 { Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-File", $winDragonScriptPath, "-RunChoice", "7" -Wait }
                            Default { Write-Host "Invalid selection" -ForegroundColor Red }
                        }
                    }
                    catch {
                        Write-Host "Error executing script: $_" -ForegroundColor Red
                        $outputTextBox.Text += "`nError executing script: $_"
                    }
                })
        })

    $grid.Children.Add($button) | Out-Null
    [System.Windows.Controls.Grid]::SetRow($button, [math]::Floor($index / 3) + 1)
    [System.Windows.Controls.Grid]::SetColumn($button, $index % 3)
    $index++
}

# Add Grid to Maintenance Tab
$maintenanceTab.Content = $grid

# Add Maintenance Tab to TabControl
$tabControl.Items.Add($maintenanceTab) | Out-Null

# Create a DockPanel to hold Menu and Content
$dockPanel = New-Object System.Windows.Controls.DockPanel
$dockPanel.Children.Add($menu) | Out-Null
$dockPanel.Children.Add($tabControl) | Out-Null

# Add DockPanel to Window
$window.Content = $dockPanel

# Call the function with the message
Show-StatusMessage -message "running"

# Show Window
$window.ShowDialog()