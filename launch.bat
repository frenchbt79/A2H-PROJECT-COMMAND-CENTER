@echo off
REM ══════════════════════════════════════════════════════════
REM  Project Dashboard — Always launches latest build
REM ══════════════════════════════════════════════════════════
set "APP_DIR=C:\Users\bfren\OneDrive\Desktop\0-AI Apps\Project Dashboard\project_command_center"
set "EXE=%APP_DIR%\build\windows\x64\runner\Release\project_command_center.exe"

cd /d "%APP_DIR%"

REM If exe exists, just launch it. User can rebuild separately.
if exist "%EXE%" (
    start "" "%EXE%"
) else (
    echo No build found. Building now (first time only)...
    flutter build windows --release
    if exist "%EXE%" (
        start "" "%EXE%"
    ) else (
        echo Build failed. Open terminal and run: flutter build windows --release
        pause
    )
)
