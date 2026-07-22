@echo off
REM Double-click this to launch the subtitle shade bar.
REM -STA is required for Windows Forms; -ExecutionPolicy Bypass avoids script-blocking.
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0SubtitleShade.ps1"
