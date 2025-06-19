<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Copilot Instructions for Windows Program Closer

This is a Windows scripting project that provides PowerShell and batch scripts for closing specific programs.

## Project Context
- **Language**: PowerShell with batch file wrappers
- **Platform**: Windows
- **Purpose**: Safely close specified Windows programs with various options

## Coding Guidelines
- Use PowerShell best practices and proper error handling
- Maintain compatibility with Windows PowerShell 5.1 and PowerShell Core
- Include comprehensive logging and verbose output options
- Follow Windows scripting conventions for batch files
- Implement graceful shutdown before force closing processes

## Key Features to Maintain
- Configuration file support for default programs
- Command-line parameter flexibility
- Graceful vs force close options
- Comprehensive logging with timestamps
- Preview/WhatIf mode for safe testing
- Cross-compatible batch file wrappers

## Security Considerations
- Always validate process names before closing
- Implement proper error handling for access denied scenarios
- Log all actions for audit trail
- Use least-privilege approach when possible

## Testing Approach
- Test with various process names and scenarios
- Verify both graceful and force close methods
- Test configuration file parsing
- Validate logging functionality
- Ensure batch file parameter passing works correctly
