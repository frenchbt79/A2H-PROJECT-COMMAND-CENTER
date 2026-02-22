$ws = New-Object -ComObject WScript.Shell
$shortcut = $ws.CreateShortcut("C:\Users\bfren\OneDrive\Desktop\Project Dashboard.lnk")
$shortcut.TargetPath = "C:\Users\bfren\OneDrive\Desktop\0-AI Apps\Project Dashboard\project_command_center\build\windows\x64\runner\Release\project_command_center.exe"
$shortcut.WorkingDirectory = "C:\Users\bfren\OneDrive\Desktop\0-AI Apps\Project Dashboard\project_command_center\build\windows\x64\runner\Release"
$shortcut.Description = "A2H Project Command Center"
$shortcut.Save()
Write-Host "Desktop shortcut created: Project Dashboard.lnk"
