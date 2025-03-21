# Autopilot Hardware Hash Collector 🚀

This script collects the hardware hash required for enrolling a device in Windows Autopilot. It simplifies the process for IT administrators and ensures accurate device information is captured.

## Requirements

*   PowerShell 5.1 or later
*   Internet connection (for installing `Get-WindowsAutoPilotInfo` in WinPE)

## User Guide 📖

1.  **Start PowerShell:**
    *   In the Out-of-Box Experience (OOBE), press **Shift+F10** to open a command prompt, then type `powershell` and press Enter.
    *   In a full Windows installation, search for "PowerShell" and run it.

2.  **Run the script:**
    ```powershell
    .\\Collect-AutopilotInfo.ps1
    ```

3.  **Follow the prompts:**
    *   The script will automatically install the `Get-WindowsAutoPilotInfo` script if needed (requires an internet connection).
    *   It will detect whether you are running in WinPE (OOBE) or a full OS environment.
    *   The hardware hash will be collected and saved to a CSV file (e.g., `AutopilotHWID_20231027103000.csv`).
    *   You will be prompted to select a USB drive to copy the file to (if a removable drive is detected). If multiple drives are present, you'll see a numbered list. Enter the number corresponding to your desired drive, or press Enter to skip copying.
    *   If you choose to copy the file, you'll be asked if you want to eject the USB drive.

## Troubleshooting 🛠️

*   **No internet connection:** If you're in WinPE and don't have an internet connection, the `Get-WindowsAutoPilotInfo` script cannot be installed. Connect to the internet and try again.
*   **Script installation failure:** Ensure you have a stable internet connection. If the installation still fails, you may need to manually download and install the script from the Microsoft PowerShell Gallery.
*   **Error getting hardware hash:** If an error occurs while collecting the hardware hash, ensure that the `Get-WindowsAutoPilotInfo` script is installed correctly and that you have the necessary permissions.
*   **USB Drive Not Detected:** Make sure the USB drive is properly connected and recognized by the system. Try a different USB port if necessary.
*   **File Copy Error:** Ensure the USB drive is not write-protected and has enough free space.

## License

This project is licensed under the MIT License - see the `Collect-AutopilotInfo.ps1` file for details.