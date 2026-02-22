$env:PATH = "C:\Program Files\Git\cmd;C:\Windows\System32;C:\Windows;C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin;C:\Users\bfren\flutter\bin;C:\Users\bfren\flutter\bin\cache\dart-sdk\bin;$env:PATH"
Set-Location 'C:\Users\bfren\Desktop\All Apps\Project Dashboard\project_command_center'
Stop-Process -Name project_command_center -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "=== Starting Debug build ==="
$proc = Start-Process -FilePath 'C:\Windows\System32\cmd.exe' -ArgumentList '/c','C:\Users\bfren\flutter\bin\flutter.bat','build','windows','--debug' -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$PSScriptRoot\_build_stdout.txt" -RedirectStandardError "$PSScriptRoot\_build_stderr.txt"
Write-Host "=== Exit code: $($proc.ExitCode) ==="
Get-Content "$PSScriptRoot\_build_stdout.txt"
Write-Host "--- STDERR ---"
Get-Content "$PSScriptRoot\_build_stderr.txt"
