@echo off
setlocal enabledelayedexpansion
title Vim Developer Environment Launcher // CMD Engine
color 0A

echo =======================================================================
echo   VIM FOR DEVELOPERS ENGINE // WINDOWS 10 CMD LAUNCHER
echo =======================================================================
echo.

:: 1. Search for Native Vim Executable Installation Paths
set "VIM_EXE_PATH="

if exist "C:\Program Files (x86)\Vim\vim91\vim.exe" (
    set "VIM_EXE_PATH=C:\Program Files (x86)\Vim\vim91\vim.exe"
) else if exist "C:\Program Files\Vim\vim91\vim.exe" (
    set "VIM_EXE_PATH=C:\Program Files\Vim\vim91\vim.exe"
) else if exist "C:\Program Files (x86)\Vim\vim90\vim.exe" (
    set "VIM_EXE_PATH=C:\Program Files (x86)\Vim\vim90\vim.exe"
) else if exist "C:\Program Files\Vim\vim90\vim.exe" (
    set "VIM_EXE_PATH=C:\Program Files\Vim\vim90\vim.exe"
)

:: Fallback Check to see if Vim is already added globally to Windows PATH variables
if not defined VIM_EXE_PATH (
    where vim.exe >nul 2>&1
    if !errorLevel! equ 0 (
        set "VIM_EXE_PATH=vim.exe"
    )
)

:: Error check if script fails to find a valid installation
if not defined VIM_EXE_PATH (
    color 0C
    echo [ERROR] Native Vim installation could not be located on this machine.
    echo         Please verify Vim is installed to default paths or added to system PATH variables.
    echo.
    pause
    exit /b 1
)

:: 2. Identify and Point to Target Config Core (_vimrc)
set "CUSTOM_VIMRC=%~dp0_vimrc"

if not exist "%CUSTOM_VIMRC%" (
    if exist "%USERPROFILE%\_vimrc" (
        set "CUSTOM_VIMRC=%USERPROFILE%\_vimrc"
    )
)

echo [INFO] Vim Binary Path:  !VIM_EXE_PATH!
echo [INFO] Config Root File:   %CUSTOM_VIMRC%
echo.
echo [*] Initializing isolated development workspace runtime context...
echo.

:: 3. Launch the Text Buffer Interface
:: -u flags down the specific developer configuration profile matrix directly
if "%~1"=="" (
    "!VIM_EXE_PATH!" -u "%CUSTOM_VIMRC%" .
) else (
    "!VIM_EXE_PATH!" -u "%CUSTOM_VIMRC%" %*
)

exit /b 0
