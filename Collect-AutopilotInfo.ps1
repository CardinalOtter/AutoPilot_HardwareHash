# Author: Per Björlefeldt
# Collect-AutopilotInfo.ps1

# MIT License
#
# Copyright (c) 2025 Per Björlefeldt
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# Description: This script gathers the hardware hash for Autopilot device enrollment.
# It is designed to work both in the Out-of-Box Experience (OOBE) environment (WinPE)
# and on a fully installed Windows system.

# Requirements:
# - PowerShell 5.1 or later
# - Internet connection (for WinPE, to install Get-WindowsAutoPilotInfo)

# Usage:
# 1.  Start PowerShell (in OOBE, use Shift+F10 to open CMD, then type 'powershell').
# 2.  Run this script: .\Collect-AutopilotInfo.ps1
# 3.  Follow the on-screen prompts.

# Set strict mode to enforce better coding practices.
Set-StrictMode -Version Latest

# --- Script Setup ---

Write-Host "Starting Autopilot hardware hash collection..." -ForegroundColor Green

# Define a default output file name with a timestamp.
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$defaultOutputFile = "AutopilotHWID_$timestamp.csv"

# --- Check Execution Context (WinPE or Full OS) ---

Write-Host "Checking execution environment..." -ForegroundColor Gray

# Check if we are running in WinPE.  We do this by looking for the MININT directory, which
# is typically only present in WinPE.
if (Test-Path -Path "C:\MININT") {
    $isWinPE = $true
    Write-Host "Running in WinPE (OOBE environment)." -ForegroundColor Yellow
} else {
    $isWinPE = $false
    Write-Host "Running in full OS environment." -ForegroundColor Yellow
}

# --- Install Get-WindowsAutoPilotInfo (if in WinPE) ---

if ($isWinPE) {
    Write-Host "Installing Get-WindowsAutoPilotInfo script..." -ForegroundColor Gray

    try {
        # Install the script.  -Force bypasses prompts. -Confirm:$false automatically answers "yes" to any confirmation prompts.
        Install-Script -Name Get-WindowsAutoPilotInfo -Force -Confirm:$false -ErrorAction Stop
        Write-Host "Get-WindowsAutoPilotInfo installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error installing Get-WindowsAutoPilotInfo: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Make sure you have an active internet connection." -ForegroundColor Red
        exit 1 # Exit the script with an error code.
    }

    # --- Set Execution Policy (if in WinPE) ---

    Write-Host "Setting execution policy..." -ForegroundColor Gray

    try {
        # Allow running unsigned scripts for this process only.
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force -ErrorAction Stop
        Write-Host "Execution policy set successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error setting execution policy: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# --- Get Hardware Hash ---

Write-Host "Getting hardware hash..." -ForegroundColor Gray

try {
    # Get the hardware hash and save it to the default output file.
    Get-WindowsAutoPilotInfo.ps1 -OutputFile $defaultOutputFile -ErrorAction Stop
    Write-Host "Hardware hash saved to: $defaultOutputFile" -ForegroundColor Green
}
catch {
    Write-Host "Error getting hardware hash: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# --- Detect USB Drives ---

Write-Host "Detecting USB drives..." -ForegroundColor Gray

# Get all volumes.
$volumes = Get-Volume

# Filter for removable drives (likely USB drives).
$usbDrives = $volumes | Where-Object {$_.DriveType -eq 'Removable'}

# Try to find the Windows installation USB drive by its label.
$winInstallUSB = $usbDrives | Where-Object {$_.FileSystemLabel -like "*ESD-USB*" -or $_.FileSystemLabel -like "*CCCOMA_X64FRE_EN-US_DV9*"}

if ($winInstallUSB) {
    # If we found a likely Windows installation USB, use it.
    $targetDrive = $winInstallUSB
    Write-Host "Found Windows installation USB drive: $($targetDrive.DriveLetter)" -ForegroundColor Yellow
}
else {
    # If not, show a list of all removable drives and let the user choose.
    Write-Host "Available removable drives:" -ForegroundColor Yellow
    $i = 1
    foreach ($drive in $usbDrives) {
        Write-Host "$i. $($drive.DriveLetter) ($($drive.FileSystemLabel))" -ForegroundColor Yellow
        $i++
    }

    # Prompt the user to select a drive.  Loop until they enter a valid selection.
    do {
        $selection = Read-Host "Enter the number of the drive to use, or press Enter to skip copying"
        if ([string]::IsNullOrEmpty($selection)) {
            Write-Host "Skipping file copy." -ForegroundColor Yellow
            break # Exit the loop if the user presses Enter without entering a number.
        }
        $selection = [int]$selection
    } until ($selection -ge 1 -and $selection -le $usbDrives.Count)

    # If the user made a selection, get the corresponding drive.
    if ($selection) {
        $targetDrive = $usbDrives[$selection - 1]
    }
}

# --- Copy File to USB ---
if ($targetDrive) {
    Write-Host "Copying file to $($targetDrive.DriveLetter):\" -ForegroundColor Gray

    try {
        Copy-Item -Path $defaultOutputFile -Destination "$($targetDrive.DriveLetter):\" -Force -ErrorAction Stop
        Write-Host "File copied successfully." -ForegroundColor Green

        # --- Eject USB ---
        Write-Host "Do you want to eject the USB drive ($($targetDrive.DriveLetter):)?" -ForegroundColor Yellow
        $eject = Read-Host "Enter 'Y' for Yes, or any other key for No"

        if ($eject -eq 'Y') {
            Write-Host "Ejecting USB drive..." -ForegroundColor Gray

            try {
                # Use WMI to eject the drive.
                $volume = Get-WmiObject -Class Win32_Volume | Where-Object {$_.DriveLetter -eq "$($targetDrive.DriveLetter):"}
                $volume.DriveLetter = $null  #  must set DriveLetter to null before calling Dismount
                $volume.Put() #  must call Put() to commit the change
                $volume.Dismount($false, $false) | Out-Null
                Write-Host "USB drive ejected successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Error ejecting USB drive: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "Error copying file: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- Output and Completion ---

Write-Host "Finished." -ForegroundColor Green

if (Test-Path -Path $defaultOutputFile)
{
    Write-Host "Hardware hash information saved in '$defaultOutputFile'."
}