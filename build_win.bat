@echo off
echo ============================================
echo  Project Command Center - Windows Build
echo ============================================
echo.

:: Kill running instances
echo Closing running instances...
taskkill /IM project_command_center.exe /F 2>nul
timeout /t 2 /nobreak >nul

:: Patch Flutter SDK for VS 2026
echo.
echo Patching Flutter for Visual Studio 2026...
set "VS_FILE=C:\Users\bfren\flutter\packages\flutter_tools\lib\src\windows\visual_studio.dart"
powershell -NoProfile -Command ^
  "$f = '%VS_FILE%'; " ^
  "$c = [IO.File]::ReadAllText($f); " ^
  "if ($c -match '18 =>') { Write-Host 'Already patched' } else { " ^
  "$old = \"17 => 'Visual Studio 17 2022',`n      _ => 'Visual Studio 16 2019',\"; " ^
  "$new = \"18 => 'Visual Studio 18 2026',`n      17 => 'Visual Studio 17 2022',`n      _ => 'Visual Studio 16 2019',\"; " ^
  "$c = $c.Replace($old, $new); " ^
  "[IO.File]::WriteAllText($f, $c); " ^
  "Write-Host 'Patch applied' }"

:: Build
echo.
echo Building Windows release...
cd /d "C:\Users\bfren\Desktop\All Apps\Project Dashboard\project_command_center"
call C:\Users\bfren\flutter\bin\flutter.bat build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo *** BUILD FAILED ***
    pause
    exit /b 1
)

echo.
echo ============================================
echo  BUILD SUCCESSFUL
echo ============================================
echo.
echo Launching app...
start "" "build\windows\x64\runner\Release\project_command_center.exe"
echo Done!
pause
