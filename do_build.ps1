$env:PATH = "C:\Windows\System32;C:\Windows;C:\Program Files\Git\cmd;C:\Users\bfren\flutter\bin;C:\Users\bfren\flutter\bin\cache\dart-sdk\bin;$env:PATH"
Set-Location 'C:\Users\bfren\Desktop\All Apps\Project Dashboard\project_command_center'
Write-Host "=== Starting Windows build ==="
$proc = Start-Process -FilePath 'C:\Windows\System32\cmd.exe' -ArgumentList '/c','C:\Users\bfren\flutter\bin\flutter.bat','build','windows','--release' -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$PSScriptRoot\build_out.txt" -RedirectStandardError "$PSScriptRoot\build_err.txt"
Write-Host "=== Exit code: $($proc.ExitCode) ==="
Get-Content "$PSScriptRoot\build_out.txt"
Write-Host "--- STDERR ---"
Get-Content "$PSScriptRoot\build_err.txt"
