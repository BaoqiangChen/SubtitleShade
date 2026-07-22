@echo off
REM Compiles SubtitleShade.cs into a standalone SubtitleShade.exe.
REM Uses the C# compiler (csc.exe) bundled with the .NET Framework - no SDK needed.

set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" (
    echo Could not find csc.exe. Is the .NET Framework installed?
    pause
    exit /b 1
)

"%CSC%" /nologo /target:winexe /optimize+ ^
    /out:"%~dp0SubtitleShade.exe" ^
    /reference:System.Windows.Forms.dll ^
    /reference:System.Drawing.dll ^
    "%~dp0SubtitleShade.cs"

if errorlevel 1 (
    echo.
    echo Build FAILED.
) else (
    echo.
    echo Build OK -^> SubtitleShade.exe
)
pause
