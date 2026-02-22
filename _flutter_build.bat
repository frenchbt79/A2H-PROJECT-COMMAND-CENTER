@echo off
set "PATH=C:\Program Files\Git\cmd;C:\Users\bfren\flutter\bin;%PATH%"
set "PROGRAMFILES(X86)=C:\Program Files (x86)"
set "ProgramFiles(x86)=C:\Program Files (x86)"
cd /d "C:\Users\bfren\Desktop\All Apps\Project Dashboard\project_command_center"
echo Starting Flutter build...
C:\Users\bfren\flutter\bin\flutter.bat build windows --debug
echo Build exit code: %ERRORLEVEL%
