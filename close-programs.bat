@echo off
REM Close Programs Batch Script
REM This batch file provides a simple interface to run the PowerShell script

setlocal enabledelayedexpansion

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not available or not in PATH
    pause
    exit /b 1
)

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Default options
set "FORCE_CLOSE="
set "VERBOSE="
set "WHATIF="
set "PROGRAMS="
set "CONFIG_FILE="

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :run_script
if /i "%~1"=="-f" set "FORCE_CLOSE=-Force" & shift & goto :parse_args
if /i "%~1"=="--force" set "FORCE_CLOSE=-Force" & shift & goto :parse_args
if /i "%~1"=="-v" set "VERBOSE=-Verbose" & shift & goto :parse_args
if /i "%~1"=="--verbose" set "VERBOSE=-Verbose" & shift & goto :parse_args
if /i "%~1"=="-w" set "WHATIF=-WhatIf" & shift & goto :parse_args
if /i "%~1"=="--whatif" set "WHATIF=-WhatIf" & shift & goto :parse_args
if /i "%~1"=="-c" set "CONFIG_FILE=-ConfigFile '%~2'" & shift & shift & goto :parse_args
if /i "%~1"=="--config" set "CONFIG_FILE=-ConfigFile '%~2'" & shift & shift & goto :parse_args
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-?" goto :show_help

REM Treat remaining arguments as program names
if "%PROGRAMS%"=="" (
    set "PROGRAMS=-ProcessNames '%~1'"
) else (
    set "PROGRAMS=%PROGRAMS%,'%~1'"
)
shift
goto :parse_args

:run_script
echo Executing Close Programs Script...
echo.

REM Change to the script directory to ensure config file is found
cd /d "%SCRIPT_DIR%"

REM Build the PowerShell command
set "PS_COMMAND=powershell -ExecutionPolicy Bypass -File ""%SCRIPT_DIR%close-programs.ps1"" %PROGRAMS% %CONFIG_FILE% %FORCE_CLOSE% %VERBOSE% %WHATIF%"

REM Execute the PowerShell script
%PS_COMMAND%

REM Check the exit code
if %errorlevel% neq 0 (
    echo.
    echo Script execution failed with error code: %errorlevel%
    pause
    exit /b %errorlevel%
)

echo.
echo Script execution completed successfully.
pause
exit /b 0

:show_help
echo Close Programs Script - Help
echo.
echo Usage: close-programs.bat [OPTIONS] [PROGRAM_NAMES...]
echo.
echo OPTIONS:
echo   -f, --force     Force close programs without graceful shutdown
echo   -v, --verbose   Enable verbose output
echo   -w, --whatif    Show what would be closed without actually closing
echo   -c, --config    Specify custom configuration file
echo   -h, --help      Show this help message
echo.
echo EXAMPLES:
echo   close-programs.bat                    - Close programs from config file
echo   close-programs.bat notepad chrome    - Close specific programs
echo   close-programs.bat -f -v notepad     - Force close notepad with verbose output
echo   close-programs.bat -w                - Preview what would be closed
echo   close-programs.bat -c custom.txt     - Use custom configuration file
echo.
pause
exit /b 0
