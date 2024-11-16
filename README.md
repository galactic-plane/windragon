![WinDragon](/img/windragon.jpeg)

# 🐉 WinDragon Maintenance Script - vBeta

This script provides an interactive menu-driven interface for performing various maintenance tasks on a Windows machine. Tasks include backup, repair, cleanup, drive optimization, or all tasks sequentially.

## 🖥️ Supported Operating Systems
- Windows 10
- Windows 11

**Note:** This script relies on PowerShell commands and tools like DISM, Robocopy, and SFC, which are supported on the above-listed versions of Windows.

## 🚀 How to Run the Script
1. Open PowerShell as an Administrator.
2. Navigate to the directory where this script is located.
   - Use the `cd` command to change directories. Example: `cd C:\path\to\script`
3. Run the script by typing: `.\WinDragon.ps1`
4. Follow the interactive prompts to select the tasks you wish to perform.

## 📋 Requirements
- PowerShell 7.4.6 or newer
- Administrator privileges to perform system-level operations like repair, cleanup, and optimization.
- Internet connection for software updates and online searches.

## 🌟 Features
- **🔄 Mirror Backup:** Uses Robocopy to create a mirror backup of specified directories.
- **🔧 Repair Tasks:** Utilizes DISM and SFC to check and repair system health.
- **📦 Update Installed Software:** Updates all installed software using WinGet.
- **🧹 Cleanup Tasks:** Performs advanced disk cleanup using Windows Clean Manager.
- **💽 Drive Optimization:** Optimizes SSDs and HDDs using appropriate methods.
- **ℹ️ System Information:** Collects and displays detailed system information.
- **📊 Event Log Analysis:** Analyzes system event logs for errors and warnings.
- **🔍 Online Search:** Generates a Bing search URL for the given information.

## 🔧 Functions
### 🐉 Show-Dragon
Displays an ASCII art dragon.

### 💬 Show-Message
Displays a message with a decorative border in yellow color.

### ❌ Show-Error
Displays an error message with a decorative border in red color.

### 📋 Show-Menu
Displays a task menu for the user to select from various maintenance tasks.

### 📂 Get-BackupPaths
Prompts the user to enter the source and destination directories for a backup operation.

### 🛠️ Catcher
Handles errors that occur during various tasks and collects those errors for a summary report.

### 📝 Write-Log
Logs messages to a specified log file located in a dated folder.

### 🛡️ Start-DefenderScan
Runs a virus scan using Windows Defender based on the current status.

### 🔄 Start-Backup
Initiates a backup operation using Robocopy.

### 🔧 Start-Repair
Performs a series of system repair tasks using various system tools.

### 📦 Start-WinGetUpdate
Installs or updates WinGet and updates all installed packages.

### 🧹 Start-Cleanup
Executes an advanced disk cleanup using the built-in Windows tool.

### 💽 Start-Optimization
Performs disk optimization on all physical drives detected by the system.

### ℹ️ Start-PCInfo
Collects and displays detailed information about the computer's hardware and system configuration.

### 🔍 Search-OnlineForInfo
Generates a Bing search URL for the given information.

### 📊 Start-EventLogAnalysis
Analyzes system event logs for errors and warnings.

## ⚠️ Disclaimer
You are running this script at your own risk. Please ensure you have backups of your important data before running any maintenance tasks.

## 📜 License
This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 👤 Author
Daniel Penrod

