@echo off
cd /d "C:\Users\bfren\Desktop\All Apps\Project Dashboard\project_command_center"
echo === DART VERSION ===
C:\Users\bfren\flutter\bin\cache\dart-sdk\bin\dart.exe --version
echo === FLUTTER ANALYZE ===
C:\Users\bfren\flutter\bin\flutter.bat analyze --no-pub --no-fatal-infos 2>&1
echo === DONE (exit code: %ERRORLEVEL%) ===
