# Autopilot Hardware Hash Script Plan

This document outlines the plan for creating a PowerShell script (`Collect-AutopilotInfo.ps1`) to simplify gathering hardware hashes for Autopilot device deployment.

## Script Name

`Collect-AutopilotInfo.ps1`

## Requirements

*   **Output Format:** CSV
*   **Filename:**  A default will be provided, but the specific name is not critical. (e.g., `AutopilotHWID_{timestamp}.csv`)
*   **USB Drive Handling:**
    *   Attempt to automatically detect the Windows installation USB drive.
    *   If not found, prompt the user to select a drive.
    *   After copying the CSV, ask the user if they want to eject the USB drive.
*   **Installation:** The script must handle the installation of the `Get-WindowsAutoPilotInfo` script and set the execution policy, as these are not pre-configured in the OOBE environment.
*   **Environment:** Primarily designed for OOBE, but should also work on an already installed system.
*   **User Interface:** Provide a checklist-style output for clarity.
* **Comments:** Include comprehensive comments in the code.

## Plan

1.  **Script Setup:**
    *   Begin the script with comments explaining its purpose and usage.
    *   Set the script to use strict mode (`Set-StrictMode -Version Latest`).
    *   Define a default output file name (e.g., `AutopilotHWID_{timestamp}.csv`).

2.  **Check Execution Context:**
    *   Determine if the script is running in a WinPE environment (likely during OOBE). This can be done by checking for the existence of a specific environment variable or file path that is only present in WinPE.

3.  **Install `Get-WindowsAutoPilotInfo` (if in WinPE):**
    *   Use an `if` statement to conditionally install the script only if running in WinPE.
    *   Use `Install-Script -Name Get-WindowsAutoPilotInfo -Force -Confirm:$false` to install the script without user interaction.
    *   Handle potential errors (e.g., no internet connection) gracefully.

4.  **Set Execution Policy (if in WinPE):**
    *   Within the same `if` statement as step 3, set the execution policy to allow running the script.
    *   Use `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force` to bypass prompts.

5.  **Get Hardware Hash:**
    *   Call `Get-WindowsAutoPilotInfo.ps1` with the `-OutputFile` parameter, using the default filename defined earlier.
    *   Capture the output and check for errors.

6.  **Detect USB Drives:**
    *   Use `Get-Volume` to list available drives.
    *   Filter the list to identify potential USB drives (e.g., by checking `DriveType` and `FileSystemLabel`). Look for common labels like "ESD-USB" or similar.
    *   If a likely Windows installation USB is found, proceed to copy the file to it.
    *   If no suitable USB is found automatically, present a list of available drives to the user and prompt them to choose one.

7.  **Copy File to USB:**
    *   If a USB drive is identified (either automatically or by user selection), copy the CSV file to the root of the drive.
    *   Handle potential errors (e.g., insufficient space, write-protected drive).

8.  **Eject USB:**
    *   After successful copy, ask the user if they want to eject the USB drive.
    *   If yes, use PowerShell's capabilities (likely involving `Win32_Volume` WMI class) to eject the drive.

9.  **Output and Completion:**
    *   Provide clear, checklist-style output to the user throughout the process, indicating the status of each step.
    *   Display a final message indicating success or failure, and the location of the output file.

## Mermaid Flowchart

```mermaid
graph TD
    A[Start] --> B{Set Strict Mode};
    B --> C{Check if running in WinPE};
    C -- Yes --> D{Install Get-WindowsAutoPilotInfo};
    D --> E{Set Execution Policy};
    E --> F{Get Hardware Hash};
    C -- No --> F;
    F --> G{Detect USB Drives};
    G -- Found --> H{Copy to USB};
    G -- Not Found --> I{Prompt User to Select Drive};
    I --> H;
    H --> L{Ask to Eject USB};
    L -- Yes --> M{Eject USB};
    L -- No --> J{Output and Completion};
    M --> J;
    J --> K[End];