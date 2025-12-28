# Pop Shell Installer for Debian 13 (Trixie)

**DISCLAIMER: This is a TEST project.** Use at your own risk.

This script is designed to install the **Pop Shell** window tiling extension and **Pop Launcher** on **Debian 13 (Trixie)** running **GNOME 48** on **Wayland**.

## Requirements

*   Debian 13 (Trixie)
*   GNOME 48
*   Wayland session

## Usage

1.  Navigate to the directory containing `install.sh`.
2.  Make the script executable:
    ```bash
    chmod +x install.sh
    ```
3.  Run the installer:
    ```bash
    ./install.sh
    ```

The script will:
*   Install necessary build dependencies (requires `sudo`).
*   Build and install **Pop Launcher** (Rust).
*   Compile and install **Pop Shell** (TypeScript).
*   Optionally configure default keyboard shortcuts.

## Post-Installation

After the installation completes, **log out and log back in** to restart GNOME Shell and load the extension correctly. You can manage the extension via the **Extensions** app.

## Keyboard Shortcuts

You can view the full list of keyboard shortcuts for Pop Shell and Pop Launcher here:
[link](https://support.system76.com/articles/pop-keyboard-shortcuts/)

## Credits

This script is based on the official System76 tutorial:
[link](https://support.system76.com/articles/pop-shell/)
