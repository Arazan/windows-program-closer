# Windows Program Closer

A PowerShell-based script for closing specific Windows programs with various options and configurations.

## Features

- **Multiple execution methods**: PowerShell script with batch file wrapper
- **Flexible program specification**: Command line parameters or configuration file
- **Wildcard support**: Use `*` and `?` patterns to match multiple processes
- **Graceful and force close options**: Try graceful shutdown first, force if needed
- **Logging**: All actions are logged with timestamps
- **Preview mode**: See what would be closed without actually closing
- **Verbose output**: Detailed information about the closing process

## Files

- `close-programs.ps1` - Main PowerShell script with enhanced error handling
- `close-programs.bat` - Batch file wrapper for easier execution
- `program-list.txt` - Configuration file with programs to close
- `close-programs.log` - Log file (created automatically)

## Usage

### Using the Batch File (Recommended)

```batch
# Close programs from configuration file
close-programs.bat

# Close specific programs
close-programs.bat notepad chrome firefox

# Force close with verbose output
close-programs.bat -f -v notepad

# Preview what would be closed
close-programs.bat -w

# Use custom configuration file
close-programs.bat -c my-programs.txt
```

### Using PowerShell Directly

```powershell
# Close programs from configuration file
.\close-programs.ps1

# Close specific programs
.\close-programs.ps1 -ProcessNames "notepad", "chrome", "firefox"

# Force close programs
.\close-programs.ps1 -ProcessNames "notepad" -Force

# Preview mode
.\close-programs.ps1 -WhatIf

# Verbose output
.\close-programs.ps1 -Verbose

# Custom configuration file
.\close-programs.ps1 -ConfigFile "custom-list.txt"
```

## Command Line Options

### Batch File Options
- `-f`, `--force` - Force close programs without graceful shutdown
- `-v`, `--verbose` - Enable verbose output
- `-w`, `--whatif` - Show what would be closed without actually closing
- `-c`, `--config` - Specify custom configuration file
- `-h`, `--help` - Show help message

### PowerShell Parameters
- `-ProcessNames` - Array of process names to close
- `-ConfigFile` - Path to configuration file (default: program-list.txt)
- `-Force` - Force close programs
- `-Verbose` - Enable verbose output
- `-WhatIf` - Preview mode

## Configuration File

Edit `program-list.txt` to specify which programs should be closed by default:

```text
# Lines starting with # are comments
# List one program name per line (without .exe extension)

notepad
chrome
firefox
calculator

# Wildcard patterns are supported:
*chrome*    # Matches all Chrome-related processes
notepad*    # Matches notepad and notepad++
*office*    # Matches all Office applications
java*       # Matches all Java processes
```

### Wildcard Patterns

The script supports PowerShell wildcard patterns:
- `*` - Matches any number of characters
- `?` - Matches a single character
- `*chrome*` - Matches any process containing "chrome"
- `notepad*` - Matches processes starting with "notepad"
- `*update*` - Matches any process containing "update"

## Examples

### Close Common Programs
```batch
close-programs.bat notepad chrome firefox discord
```

### Close All Chrome-Related Processes
```batch
close-programs.bat "*chrome*"
```

### Close All Processes Starting with "java"
```batch
close-programs.bat "java*"
```

### Force Close All Programs from Config
```batch
close-programs.bat -f
```

### Preview Mode (Safe Testing)
```batch
close-programs.bat -w
```

### Verbose Logging
```batch
close-programs.bat -v notepad
```

## Safety Features

1. **Graceful Close First**: The script tries to close programs gracefully before forcing
2. **Process Verification**: Checks if processes exist before attempting to close
3. **Error Handling**: Proper error handling and logging
4. **Preview Mode**: Test what would be closed with `-w` or `-WhatIf`
5. **Logging**: All actions are logged to `close-programs.log`

## Requirements

- Windows with PowerShell (Windows 7/Server 2008 R2 or later)
- PowerShell execution policy allowing script execution

## Setting Up PowerShell Execution Policy

If you get execution policy errors, run this command as Administrator:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Troubleshooting

### Common Issues

1. **"Access is denied" / "Exception calling Kill"**
   - Run Command Prompt or PowerShell as Administrator
   - Some processes (services, system processes) require elevated permissions
   - Check the Troubleshooting section below for detailed solutions

2. **"Execution of scripts is disabled"**
   - Run the batch file instead: `close-programs.bat`
   - Or set PowerShell execution policy (see above)

3. **"Process not found"**
   - Make sure the process name is correct (without .exe)
   - Use Task Manager to verify the exact process name

4. **Process won't close gracefully**
   - Use force mode: `close-programs.bat -f`
   - Some processes may need to be closed from their system tray first

### Log File

Check `close-programs.log` for detailed information about script execution, including:
- Which programs were found and closed
- Any errors encountered
- Timestamps for all actions

## Customization

### Adding More Programs

Edit `program-list.txt` and add program names (one per line, without .exe extension):

```text
# My custom programs
myapp
anotherapp
```

### Creating Custom Scripts

You can create specialized scripts for different scenarios:

```batch
# Gaming session cleanup
close-programs.bat steam discord obs64

# Work day cleanup  
close-programs.bat chrome slack teams outlook

# Development cleanup
close-programs.bat code devenv notepad++
```

## License

This project is released under the MIT License. Feel free to modify and distribute as needed.

---

# Troubleshooting Guide

## Common "Access Denied" Scenarios and Solutions

### 1. **Standard User vs Administrator**
**Problem**: Process requires administrator privileges to close
```
[ERROR] Access denied terminating 'ProcessName' (Owner: SYSTEM\User). Try running as Administrator.
```
**Solutions**:
- Right-click Command Prompt → "Run as Administrator", then run `close-programs.bat`
- Right-click PowerShell → "Run as Administrator"
- Use: `powershell -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File close-programs.ps1' -Verb RunAs"`

### 2. **System Services**
**Problem**: Trying to close a Windows service process
```
[WARNING] Skipping process 'ProcessName' (PID: 1234): Windows service: ServiceName
```
**Solutions**:
- Stop the service first: `net stop ServiceName` or `Stop-Service ServiceName`
- Use Services.msc to stop the service manually
- Some services cannot be stopped (critical system services)

### 3. **Protected Processes**
**Problem**: Process is protected by Windows
```
[ERROR] Access denied closing 'ProcessName' (Owner: NT AUTHORITY\SYSTEM). Process may be protected.
```
**Solutions**:
- These are usually system processes that shouldn't be closed
- Remove from your program list if it's a system process
- Use Task Manager as Administrator if absolutely necessary

### 4. **Process Already Closed**
**Problem**: Process exits before we can close it
```
[INFO] Process 'ProcessName' (PID: 1234) has already exited
```
**Solution**: This is normal behavior, no action needed

## Safe Testing Approaches

### Preview Mode First
Always test with preview mode before actual closing:
```batch
# Safe preview
close-programs.bat -w

# After confirming, run normally
close-programs.bat
```

### Check Process Ownership
Use Task Manager to see process details:
1. Open Task Manager (Ctrl+Shift+Esc)
2. Go to "Details" tab
3. Right-click columns → Add "User name"
4. Check which user owns the process

## Program-Specific Solutions

### Common Programs That May Need Admin Rights:
- **System utilities**: Task Manager, Registry Editor
- **Security software**: Antivirus, Windows Defender
- **Hardware utilities**: Graphics drivers, system monitoring tools
- **Services**: Background services, system daemons

### MouseWithoutBorders Specific:
MouseWithoutBorders may run with elevated privileges. Options:
1. Exit from system tray first
2. Run script as Administrator
3. Stop the service: `net stop "Mouse without Borders"`

## Alternative Closing Methods

### 1. Using TASKKILL Command
```batch
# Graceful close
taskkill /IM ProcessName.exe

# Force close
taskkill /F /IM ProcessName.exe

# Close by PID
taskkill /F /PID 1234
```

### 2. Using WMIC
```batch
# Get process info
wmic process where name="ProcessName.exe" get ProcessId,CommandLine

# Terminate process
wmic process where name="ProcessName.exe" delete
```

### 3. Using PowerShell Stop-Process
```powershell
# Graceful stop
Stop-Process -Name "ProcessName"

# Force stop
Stop-Process -Name "ProcessName" -Force

# Stop by ID
Stop-Process -Id 1234 -Force
```

## Configuration Best Practices

### Safe Program List
Focus on user applications rather than system processes:
```text
# Safe to close (user applications)
notepad
chrome
firefox
vlc
spotify
discord

# Avoid system processes
# svchost
# winlogon  
# csrss
```

### Testing New Programs
When adding new programs to your list:
1. Add one at a time
2. Test with `-w` (preview mode) first
3. Check if it requires admin rights
4. Verify it closes properly

## Emergency Recovery

If you accidentally close critical processes:
1. **Restart Windows** - safest option
2. **Start Task Manager**: Ctrl+Shift+Esc
3. **Run new process**: File → Run new task → `explorer.exe`
4. **System Restore**: If system becomes unstable

## Getting Help

### Check the Log File
Always check `close-programs.log` for detailed error information:
```batch
type close-programs.log | findstr ERROR
```

### Process Information Commands
```powershell
# List all processes
Get-Process | Sort-Object Name

# Get specific process details
Get-Process ProcessName | Select-Object *

# Check if running as admin
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```
