# Close Specific Programs Script
# This PowerShell script closes specified programs by name or process ID

param(
    [string[]]$ProcessNames = @(),
    [string]$ConfigFile = "program-list.txt",
    [switch]$Force,
    [switch]$Verbose,
    [switch]$WhatIf
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    
    # Also write to log file
    $logFile = "close-programs.log"
    Add-Content -Path $logFile -Value $logMessage
}

function Get-ProgramsFromConfig {
    param([string]$ConfigPath)
    
    # If the config path is not absolute, make it relative to the script directory
    if (![System.IO.Path]::IsPathRooted($ConfigPath)) {
        $scriptDir = $PSScriptRoot
        if ($scriptDir) {
            $ConfigPath = Join-Path $scriptDir $ConfigPath
        }
    }
    
    if (Test-Path $ConfigPath) {
        $programs = Get-Content $ConfigPath | Where-Object { 
            $_.Trim() -ne "" -and !$_.StartsWith("#") 
        }
        return $programs
    } else {
        Write-Log "Configuration file not found: $ConfigPath" "WARNING"
        Write-Log "Searched in: $(Resolve-Path -Path $ConfigPath -ErrorAction SilentlyContinue)" "WARNING"
        return @()
    }
}

function Close-Program {
    param(
        [string]$ProcessName,
        [bool]$ForceClose = $false,
        [bool]$ShowWhatIf = $false
    )
    
    try {
        # Remove .exe extension if present for consistency
        $cleanProcessName = $ProcessName -replace '\.exe$', ''
        
        # Get all processes matching the name
        $processes = Get-Process -Name $cleanProcessName -ErrorAction SilentlyContinue
        
        if ($processes) {
            $isElevated = Test-IsElevated
            
            foreach ($process in $processes) {
                # Check if we can safely close this process
                $canClose, $reason = Test-CanCloseProcess -Process $process
                
                if (!$canClose) {
                    Write-Log "Skipping process '$($process.ProcessName)' (PID: $($process.Id)): $reason" "WARNING"
                    continue
                }
                
                # Get process owner for better error reporting
                $owner = Get-ProcessOwner -Process $process
                
                if ($ShowWhatIf) {
                    Write-Log "What if: Would close process '$($process.ProcessName)' (PID: $($process.Id), Owner: $owner)" "WHATIF"
                } else {
                    try {
                        if ($ForceClose) {
                            try {
                                $process.Kill()
                                Write-Log "Force closed process '$($process.ProcessName)' (PID: $($process.Id))" "SUCCESS"
                            } catch [System.InvalidOperationException] {
                                Write-Log "Process '$($process.ProcessName)' (PID: $($process.Id)) has already exited" "INFO"
                            } catch [System.ComponentModel.Win32Exception] {
                                if ($_.Exception.NativeErrorCode -eq 5) {  # Access Denied
                                    if ($isElevated) {
                                        Write-Log "Access denied closing '$($process.ProcessName)' (Owner: $owner). Process may be protected or a system service." "ERROR"
                                        Write-Log "Suggestion: Try using Task Manager or stopping the associated service first." "INFO"
                                    } else {
                                        Write-Log "Access denied closing '$($process.ProcessName)' (Owner: $owner). Try running as Administrator." "ERROR"
                                    }
                                } else {
                                    Write-Log "Failed to force close '$($process.ProcessName)': $($_.Exception.Message)" "ERROR"
                                }
                            }
                        } else {
                            # Try graceful close first
                            $closed = $process.CloseMainWindow()
                            if ($closed) {
                                Start-Sleep -Seconds 3
                                
                                # Refresh process to check if it's still running
                                try {
                                    $process.Refresh()
                                    if (!$process.HasExited) {
                                        Write-Log "Process '$($process.ProcessName)' did not close gracefully, attempting force close..." "WARNING"
                                        try {
                                            $process.Kill()
                                            Write-Log "Force closed process '$($process.ProcessName)' (PID: $($process.Id))" "SUCCESS"
                                        } catch [System.ComponentModel.Win32Exception] {
                                            if ($_.Exception.NativeErrorCode -eq 5) {  # Access Denied
                                                if ($isElevated) {
                                                    Write-Log "Access denied force closing '$($process.ProcessName)' (Owner: $owner). Process may be protected." "ERROR"
                                                } else {
                                                    Write-Log "Access denied force closing '$($process.ProcessName)' (Owner: $owner). Try running as Administrator." "ERROR"
                                                }
                                            } else {
                                                Write-Log "Failed to force close '$($process.ProcessName)': $($_.Exception.Message)" "ERROR"
                                            }
                                        }
                                    } else {
                                        Write-Log "Gracefully closed process '$($process.ProcessName)' (PID: $($process.Id))" "SUCCESS"
                                    }
                                } catch [System.InvalidOperationException] {
                                    Write-Log "Successfully closed process '$($process.ProcessName)' (PID: $($process.Id))" "SUCCESS"
                                }
                            } else {
                                Write-Log "Process '$($process.ProcessName)' does not have a main window. Attempting direct termination..." "INFO"
                                try {
                                    $process.Kill()
                                    Write-Log "Terminated process '$($process.ProcessName)' (PID: $($process.Id))" "SUCCESS"
                                } catch [System.ComponentModel.Win32Exception] {
                                    if ($_.Exception.NativeErrorCode -eq 5) {  # Access Denied
                                        if ($isElevated) {
                                            Write-Log "Access denied terminating '$($process.ProcessName)' (Owner: $owner). Process may be protected." "ERROR"
                                        } else {
                                            Write-Log "Access denied terminating '$($process.ProcessName)' (Owner: $owner). Try running as Administrator." "ERROR"
                                        }
                                    } else {
                                        Write-Log "Failed to terminate '$($process.ProcessName)': $($_.Exception.Message)" "ERROR"
                                    }
                                }
                            }
                        }
                    } catch {
                        Write-Log "Unexpected error closing process '$($process.ProcessName)' (PID: $($process.Id)): $($_.Exception.Message)" "ERROR"
                    }
                }
            }
        } else {
            Write-Log "No running processes found for '$ProcessName'" "INFO"
        }
    } catch {
        Write-Log "Error processing '$ProcessName': $($_.Exception.Message)" "ERROR"
    }
}

function Test-IsElevated {
    # Check if running with administrator privileges
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Get-ProcessOwner {
    param([System.Diagnostics.Process]$Process)
    try {
        $owner = (Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($Process.Id)").GetOwner()
        if ($owner.Domain -and $owner.User) {
            return "$($owner.Domain)\$($owner.User)"
        }
        return "Unknown"
    } catch {
        return "Unable to determine"
    }
}

function Test-CanCloseProcess {
    param([System.Diagnostics.Process]$Process)
    
    # Check if it's a critical system process
    $criticalProcesses = @('winlogon', 'csrss', 'smss', 'services', 'lsass', 'svchost')
    if ($Process.ProcessName -in $criticalProcesses) {
        return $false, "Critical system process"
    }
    
    # Check if it's a Windows service
    try {
        $service = Get-WmiObject -Class Win32_Service -Filter "ProcessId = $($Process.Id)" -ErrorAction SilentlyContinue
        if ($service) {
            return $false, "Windows service: $($service.Name)"
        }
    } catch {
        # Continue if we can't check service status
    }
    
    return $true, ""
}

# Main execution
Write-Log "Starting Close Programs Script" "INFO"

# Check if running with elevated privileges
$isElevated = Test-IsElevated
if ($isElevated) {
    Write-Log "Running with Administrator privileges" "INFO"
} else {
    Write-Log "Running with standard user privileges (some processes may require Administrator access)" "INFO"
}

# Determine which programs to close
$programsToClose = @()

if ($ProcessNames.Count -gt 0) {
    # Use programs specified as parameters
    $programsToClose = $ProcessNames
    Write-Log "Using programs from command line parameters: $($ProcessNames -join ', ')" "INFO"
} else {
    # Use programs from configuration file
    $programsToClose = Get-ProgramsFromConfig -ConfigPath $ConfigFile
    Write-Log "Using programs from configuration file: $ConfigFile" "INFO"
}

if ($programsToClose.Count -eq 0) {
    Write-Log "No programs specified to close. Use -ProcessNames parameter or configure $ConfigFile" "WARNING"
    exit 1
}

# Display programs that will be closed
Write-Log "Programs to close: $($programsToClose -join ', ')" "INFO"

# Close each program
foreach ($program in $programsToClose) {
    if ($Verbose) {
        Write-Log "Processing: $program" "INFO"
    }
    Close-Program -ProcessName $program -ForceClose $Force -ShowWhatIf $WhatIf
}

Write-Log "Close Programs Script completed" "INFO"
