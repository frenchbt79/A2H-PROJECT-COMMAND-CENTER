@echo off
echo [BUILD] Starting Windows release build...
cd /d "C:\Users\bfren\Desktop\All Apps\Project Dashboard\project_command_center"
echo [BUILD] Dir: %CD%
call C:\Users\bfren\flutter\bin\flutter.bat build windows --release
echo [BUILD] Exit code: %ERRORLEVEL%
echo [BUILD] Done.
