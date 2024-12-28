# scrcpy-cli-tool

A simple command-line tool for automatically updating and managing scrcpy using PowerShell.

## Features

- Automatically checks for the latest version of scrcpy
- Downloads and installs scrcpy
- Provides easy-to-use command-line interface

## Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/theisoj/scrcpy-cli-tool.git
    ```
2. Navigate to the project directory:
    ```sh
    cd scrcpy-cli-tool
    ```

## Usage

To update and manage scrcpy, place the `scrcpy-cli-tool.ps1` file in the following directory based on your operating system:

- **Windows**: `C:\scrcpy`
- **macOS**: `/usr/local/bin/scrcpy`
- **Linux**: `/usr/local/bin/scrcpy`

Then, run the following command in PowerShell:
```powershell
.\scrcpy-cli-tool.ps1
```

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License.

## Prerequisites

Ensure that PowerShell is installed on your operating system. If it is not installed, follow the instructions below to install it.

### Windows
PowerShell comes pre-installed on Windows 10 and later. For older versions, download and install it from the [official PowerShell GitHub releases page](https://github.com/PowerShell/PowerShell/releases).

### macOS

1. Open a terminal window.
2. Install Homebrew if it is not already installed:
    ```sh
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```
3. Use Homebrew to install PowerShell:
    ```sh
    brew install --cask powershell
    ```

### Linux

1. Open a terminal window.
2. Follow the instructions for your specific distribution from the [official PowerShell GitHub releases page](https://github.com/PowerShell/PowerShell/releases).

## Making the Script Globally Available

To make the `scrcpy-cli-tool.ps1` script globally available on your operating system, you need to add its directory to your system's environment variables.

### Windows

1. Open the Start Menu and search for "Environment Variables".
2. Select "Edit the system environment variables".
3. In the System Properties window, click on the "Environment Variables" button.
4. In the Environment Variables window, find the `Path` variable in the "System variables" section and select it.
5. Click "Edit" and then "New" to add a new entry.
6. Enter `C:\scrcpy` and click "OK" to save the changes.

### macOS and Linux

1. Open a terminal window.
2. Edit your shell profile file (e.g., `~/.bashrc`, `~/.zshrc`, or `~/.profile`) using a text editor.
3. Add the following line to the file:
    ```sh
    export PATH=$PATH:/usr/local/bin/scrcpy
    ```
4. Save the file and run the following command to apply the changes:
    ```sh
    source ~/.bashrc  # or the appropriate profile file
    ```

After completing these steps, you should be able to run the `scrcpy-cli-tool.ps1` script from any terminal or command prompt window.

## Copyright
© 2024 theisoj. All rights reserved.