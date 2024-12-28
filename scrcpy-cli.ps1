<#
.SYNOPSIS
CLI-työkalu scrcpy:n hallintaan: asennus, päivitys ja poisto.

.DESCRIPTION
Skripti tarkistaa scrcpy:n version, lataa uusimman version GitHubista ja asentaa sen käyttäjän valitsemaan paikkaan.

#>

# --- Funktiot ---
function Show-Menu {
    Clear-Host
    Write-Output "----------------------------------"
    Write-Output "scrcpy CLI Tool"
    Write-Output "----------------------------------"
    Write-Output "1. Check installed version"
    Write-Output "2. Install/Update scrcpy"
    Write-Output "3. Uninstall scrcpy"
    Write-Output "0. Exit"
    Write-Output "----------------------------------"
    $choice = Read-Host "Enter your choice (0-3)"
    return $choice
}

function Check-Installed-Version {
    Write-Output "Checking installed scrcpy version..."
    $currentVersion = ""
    try {
        $scrcpyOutput = & scrcpy.exe -v 2>$null
        $scrcpyOutputLines = $scrcpyOutput -split "`n"
        foreach ($line in $scrcpyOutputLines) {
            if ($line -match "scrcpy (\d+\.\d+)") {
                $currentVersion = $matches[1]
                break
            }
        }
        if ($currentVersion) {
            Write-Output "Installed scrcpy version: $currentVersion"
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
    $repo = "https://api.github.com/repos/Genymobile/scrcpy/releases/latest"
    $platform = "win64"
    $scrcpyTargetPath = "C:\scrcpy"

    # Hae GitHubista uusimman version tiedot
    Write-Output "Fetching latest release from GitHub..."
    $response = Invoke-RestMethod -Uri $repo -Headers @{ 'User-Agent' = 'PowerShell' }
    $latestVersion = $response.tag_name -replace "v", ""

    # Tarkista, onko scrcpy jo asennettu ja päivitetään tarvittaessa
    Check-Installed-Version
    if ($currentVersion -eq $latestVersion) {
        Write-Output "You already have the latest scrcpy version ($latestVersion). No update needed."
        return
    }

    Write-Output "New version available: $latestVersion (Installed: $currentVersion). Proceeding with installation..."

    # Lataa uusin versio
    $downloadAsset = $response.assets | Where-Object { $_.name -like "*$platform*.zip" } | Select-Object -First 1
    if (-not $downloadAsset) {
        Write-Error "No compatible scrcpy release found for $platform. Exiting..."
        return
    }
    $downloadUrl = $downloadAsset.browser_download_url
    $zipFileName = $downloadAsset.name

    # Lataa ja pura
    $tempPath = Join-Path (Get-Location) "temp_update"
    New-Item -ItemType Directory -Force -Path $tempPath | Out-Null
    $zipFilePath = Join-Path $tempPath $zipFileName
    Write-Output "Downloading scrcpy from $downloadUrl..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath -Headers @{ 'User-Agent' = 'PowerShell' }
    Write-Output "Extracting scrcpy..."
    Expand-Archive -Path $zipFilePath -DestinationPath $tempPath -Force

    # Siirrä tiedostot
    Write-Output "Installing scrcpy to C:\scrcpy..."
    New-Item -ItemType Directory -Force -Path $scrcpyTargetPath | Out-Null
    $extractedFolder = Get-ChildItem $tempPath -Directory | Select-Object -First 1
    if ($extractedFolder -ne $null) {
        Get-ChildItem -Path $extractedFolder.FullName -Recurse | ForEach-Object {
            $destinationPath = Join-Path -Path $scrcpyTargetPath -ChildPath ($_ | Split-Path -Leaf)
            Move-Item -Path $_.FullName -Destination $destinationPath -Force
        }
    }

    # Siivoa
    Write-Output "Cleaning up temporary files..."
    Remove-Item -Path $tempPath -Recurse -Force

    Write-Output "scrcpy installed/updated successfully to $scrcpyTargetPath. Version: $latestVersion"
}

function Uninstall-Scrcpy {
    $scrcpyTargetPath = "C:\scrcpy"
    if (Test-Path -Path $scrcpyTargetPath) {
        Write-Output "Uninstalling scrcpy..."
        Remove-Item -Path $scrcpyTargetPath -Recurse -Force
        Write-Output "scrcpy uninstalled successfully."
    }
    else {
        Write-Warning "scrcpy is not installed or directory does not exist."
    }
}

# --- Pääohjelma ---
do {
    $choice = Show-Menu
    switch ($choice) {
        "1" { Check-Installed-Version }
        "2" { Install-Or-Update-Scrcpy }
        "3" { Uninstall-Scrcpy }
        "0" {
            Write-Output "Exiting. Goodbye!"
            break
        }
        default { Write-Warning "Invalid choice. Please select a valid option (0-3)." }
    }
    Write-Output "`nPress Enter to return to the menu..."
    Read-Host
} while ($true)