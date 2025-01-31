<#
.SYNOPSIS
CLI tool for managing scrcpy: installation, update, and removal.

.DESCRIPTION
The script checks the version of scrcpy, downloads the latest version from GitHub, and installs it to the user-specified location.

#>

$global:currentScriptVersion = "v2025.1.10"

# --- Functions ---
function Show-Menu {
    do {
        $choice = Read-Host "Please enter your choice (0-12)"
    } while ($choice -notmatch '^(10|11|12|[0-9])$')
    return $choice
}

function Check-Installed-Version {
    Write-Output "Checking installed scrcpy version..."
    $global:currentVersion = ""
    try {
        $scrcpyOutput = & scrcpy.exe -v 2>&1
        $scrcpyOutputLines = $scrcpyOutput -split "`n"
        foreach ($line in $scrcpyOutputLines) {
            if ($line -match "scrcpy (\d+\.\d+)") {
                $global:currentVersion = $matches[1]
                break
            }
        }
        if ($global:currentVersion) {
            Write-Output "Installed scrcpy version: $global:currentVersion"
        }
        else {
            Write-Warning "scrcpy is not installed."
        }
    }
    catch {
        Write-Warning "scrcpy is not installed or not in PATH."
    }
}

function Install-Or-Update-Scrcpy {
    param (
        [switch]$install,
        [switch]$update
    )

    $repo = "https://api.github.com/repos/Genymobile/scrcpy/releases/latest"
    $scrcpyTargetPath = "/usr/local/bin/scrcpy"

    # Determine platform
    if ($IsWindows) {
        if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            $platform = "win64"
            $scrcpyTargetPath = "C:\scrcpy"
        }
        elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
            $platform = "win32"
            $scrcpyTargetPath = "C:\scrcpy"
        }
        else {
            Write-Error "Unsupported platform: $env:PROCESSOR_ARCHITECTURE. Exiting..."
            return
        }
    }
    elseif ($IsMacOS) {
        $platform = "macos"
        $scrcpyTargetPath = "/usr/local/bin/scrcpy"
    }
    elseif ($IsLinux) {
        $platform = "linux"
        $scrcpyTargetPath = "/usr/local/bin/scrcpy"
    }
    else {
        Write-Error "Unsupported operating system. Exiting..."
        return
    }

    # Fetch latest release from GitHub
    Write-Output "Fetching latest release from GitHub..."
    $response = Invoke-RestMethod -Uri $repo -Headers @{ 'User-Agent' = 'PowerShell' } -Verbose
    $latestVersion = $response.tag_name -replace "v", ""

    if ($update) {
        # Check if scrcpy is already installed and update if necessary
        Check-Installed-Version
        if ($global:currentVersion -eq $latestVersion) {
            Write-Output "You already have the latest scrcpy version ($latestVersion). No update needed."
            return
        }
    
        Write-Output "New version available: $latestVersion (Installed: $global:currentVersion). Proceeding with update..."
    }
    elseif ($install) {
        # Check if scrcpy is already installed
        Check-Installed-Version
        if ($global:currentVersion) {
            Write-Output "scrcpy is already installed (Version: $global:currentVersion). Use the update option to update to the latest version."
            return
        }
        Write-Output "Proceeding with installation of scrcpy version $latestVersion..."
    }
    else {
        Write-Error "Please specify either -install or -update. Exiting..."
        return
    }

    # Download the latest version
    $downloadAsset = $response.assets | Where-Object { $_.name -like "*$platform*.zip" } | Select-Object -First 1
    if (-not $downloadAsset) {
        Write-Error "No compatible scrcpy release found for $platform. Exiting..."
        return
    }
    $downloadUrl = $downloadAsset.browser_download_url
    $zipFileName = $downloadAsset.name

    # Download and extract
    $tempPath = Join-Path (Get-Location) "temp_update"
    New-Item -ItemType Directory -Force -Path $tempPath | Out-Null
    $zipFilePath = Join-Path $tempPath $zipFileName
    Write-Output "Downloading scrcpy from $downloadUrl..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath -Headers @{ 'User-Agent' = 'PowerShell' } -Verbose
    Write-Output "Extracting scrcpy..."
    Expand-Archive -Path $zipFilePath -DestinationPath $tempPath -Force -Verbose

    # Move files
    Write-Output "Installing scrcpy to $scrcpyTargetPath..."
    if ($IsWindows) {
        New-Item -ItemType Directory -Force -Path $scrcpyTargetPath | Out-Null
    }
    $extractedFolder = Get-ChildItem $tempPath -Directory | Select-Object -First 1
    if ($null -ne $extractedFolder) {
        Get-ChildItem -Path $extractedFolder.FullName -Recurse -Verbose | ForEach-Object {
            $destinationPath = Join-Path -Path $scrcpyTargetPath -ChildPath ($_ | Split-Path -Leaf)
            Move-Item -Path $_.FullName -Destination $destinationPath -Force -Verbose
        }
    }

    # Clean up
    Write-Output "Cleaning up temporary files..."
    Remove-Item -Path $tempPath -Recurse -Force -Verbose

    Write-Output "scrcpy installed/updated successfully to $scrcpyTargetPath. Version: $latestVersion"
}

function Uninstall-Scrcpy {
    $scrcpyTargetPath = "C:\scrcpy"
    if (Test-Path -Path $scrcpyTargetPath) {
        $confirmation = Read-Host "Are you sure you want to uninstall scrcpy? (y/n)"
        if ($confirmation -eq 'y') {
            Clear-Host
            Write-Output "Uninstalling scrcpy..."

            # Remove scrcpy directory
            Remove-Item -Path $scrcpyTargetPath -Recurse -Force -Verbose

            Write-Output "scrcpy uninstalled successfully."
        }
        else {
            Write-Output "Uninstallation cancelled."
        }
    }
    else {
        Write-Warning "scrcpy is not installed or directory does not exist."
    }
}

function Add-Scrcpy-To-Path {
    Write-Output "Adding scrcpy to PATH..."

    $scrcpyTargetPath = "C:\scrcpy"
    if ($IsWindows) {
        $envPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
        if ($envPath -notmatch [regex]::Escape($scrcpyTargetPath)) {
            [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$scrcpyTargetPath", [System.EnvironmentVariableTarget]::Machine)
            Write-Output "scrcpy path added to the system PATH."
        }
        else {
            Write-Output "scrcpy path is already in the system PATH."
        }
    }
    else {
        Write-Warning "Adding scrcpy to PATH is only supported on Windows."
    }
}

function Remove-Scrcpy-From-Path {
    Write-Output "Removing scrcpy from PATH..."

    $scrcpyTargetPath = "C:\scrcpy"
    if ($IsWindows) {
        $envPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
        if ($envPath -match [regex]::Escape($scrcpyTargetPath)) {
            $newPath = $envPath -replace [regex]::Escape(";$scrcpyTargetPath"), ""
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
            Write-Output "scrcpy path removed from the system PATH."
        }
        else {
            Write-Output "scrcpy path is not in the system PATH."
        }
    }
    else {
        Write-Warning "Removing scrcpy from PATH is only supported on Windows."
    }
}

function Update-Script {
    param (
        [switch]$Confirm
    )

    if ($Confirm) {
        $confirmation = Read-Host "Are you sure you want to update the script? (y/n)"
        if ($confirmation -ne 'y') {
            Write-Output "Update cancelled."
            return
        }
    }

    Write-Output "Checking for script updates..."
    $scriptUrl = "https://raw.githubusercontent.com/theisoj/scrcpy-cli-tool/main/scrcpy-cli.ps1"
    $scriptPath = Get-Location | Join-Path -ChildPath "scrcpy-cli.ps1"
    $response = Invoke-RestMethod -Uri $scriptUrl -Headers @{ 'User-Agent' = 'PowerShell' }
    $newScript = $response -join "`n"
    $currentScript = Get-Content -Path $scriptPath -Raw
    if ($newScript -eq $currentScript) {
        Write-Output "You already have the latest version of the script."
    }
    else {
        Write-Output "Updating script..."
        Set-Content -Path $scriptPath -Value $newScript
        Write-Output "Script updated successfully."
    }

    Write-Output "Exiting..."
    Exit
}

# --- Main Program ---
$global:exit = $false
do {
    Clear-Host
    Write-Output "==============================="
    Write-Output "      SCRCPY CLI TOOL MENU     "
    Write-Output "==============================="
    Write-Output "1. 📥 Install Scrcpy"
    Write-Output "2. 🔄 Update Scrcpy"
    Write-Output "3. ❌ Uninstall Scrcpy"
    Write-Output "4. 🚀 Check Installed Version"
    Write-Output "5. ➕ Add Scrcpy to PATH"
    Write-Output "6. ➖ Remove Scrcpy from PATH"
    Write-Output "7. 🌐 GitHub"
    Write-Output "8. 🌐 Scrcpy GitHub"
    Write-Output "9. 🔄 Check for Script Updates"
    Write-Output "10. 👥 Credits"
    Write-Output "11. 📝 Help"
    Write-Output "12. 📄 Show Script Version"
    Write-Output "0. 🚪 Exit"
    Write-Output "==============================="
    Write-Output ""
    $choice = Show-Menu
    switch ($choice) {
        "1" {
            Clear-Host
            Install-Or-Update-Scrcpy -install
        }
        "2" {
            Clear-Host
            Install-Or-Update-Scrcpy -update
        }
        "3" {
            Uninstall-Scrcpy
        }
        "4" {
            Clear-Host
            Check-Installed-Version
        }
        "5" {
            Clear-Host
            Add-Scrcpy-To-Path
        }
        "6" {
            Clear-Host
            Remove-Scrcpy-From-Path
        }
        "7" {
            Clear-Host
            Write-Output "Opening GitHub repository..."
            Start-Process "https://github.com/theisoj/scrcpy-cli-tool"
        }
        "8" {
            Clear-Host
            Write-Output "Opening  scrcpy GitHub repository..."
            Start-Process "https://github.com/Genymobile/scrcpy"
        }
        "9" {
            Clear-Host
            Update-Script -Confirm
        }
        "10" {
            Clear-Host
            Write-Output "==============================="
            Write-Output "           CREDITS             "
            Write-Output "==============================="
            Write-Output "Script by: theisoj"
            Write-Output ""
            Write-Output "Social Media:"
            Write-Output ""
            Write-Output "GitHub: https://github.com/theisoj"
            Write-Output "X: https://x.com/jessekeskela"
            Write-Output "YouTube: https://www.youtube.com/@theisoj"
            Write-Output "Twitch: https://www.twitch.tv/theisoj"
            Write-Output "Kick: https://kick.com/theisoj"
            Write-Output "TikTok: https://www.tiktok.com/@theisoj"
            Write-Output "Instagram: https://www.instagram.com/jesseinthemiddle"
            Write-Output ""
            Write-Output "Thank you for using the SCRCPY CLI Tool!"
            Write-Output ""
            Write-Output "==============================="

        }
        "11" {
            Clear-Host
            Write-Output "==============================="
            Write-Output "            HELP               "
            Write-Output "==============================="
            Write-Output "This script is a CLI tool for managing scrcpy: installation, update, and removal."
            Write-Output ""
            Write-Output "1. Install Scrcpy: Downloads and installs the latest version of scrcpy."
            Write-Output "2. Update Scrcpy: Checks for the latest version and updates if necessary."
            Write-Output "3. Uninstall Scrcpy: Removes the installed scrcpy."
            Write-Output "4. Check Installed Version: Displays the currently installed scrcpy version."
            Write-Output "5. Add Scrcpy to PATH: Adds the scrcpy path to the system PATH."
            Write-Output "6. Remove Scrcpy from PATH: Removes the scrcpy path from the system PATH."
            Write-Output "7. GitHub: Opens the GitHub repository for this script."
            Write-Output "8. GitHub: Opens the GitHub repository for scrcpy."
            Write-Output "9. Check for Script Updates: Checks for updates to this script."
            Write-Output "10. Credits: Displays the credits and social media links."
            Write-Output "11. Help: Displays this help message."
            Write-Output "12. Show Script Version: Displays the current script version."
            Write-Output "0. Exit: Exits the script."
            Write-Output ""
            Write-Output "==============================="
        }
        "12" {
            Clear-Host
            Write-Output "==============================="
            Write-Output "        SCRIPT VERSION         "
            Write-Output "==============================="
            Write-Output "Current Script Version: $global:currentScriptVersion"
            Write-Output "==============================="
        }
        "0" {
            Clear-Host
            Write-Output "Exiting. Goodbye!"
            $global:exit = $true
        }
        default {
            Clear-Host
            Write-Warning "Invalid choice. Please select a valid option (0-12)."
        }
    }
    if (-not $global:exit) {
        Write-Output "`nPress Enter to return to the menu..."
        Read-Host
    }
} while (-not $global:exit)