$WshShell = New-Object -ComObject WScript.Shell

# Setup GitHub shortcut
$sc = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\PCC - Setup GitHub.lnk")
$sc.TargetPath = "$PSScriptRoot\setup_github.bat"
$sc.WorkingDirectory = "$PSScriptRoot"
$sc.Description = "Set up GitHub repo and deploy Project Command Center to GitHub Pages"
$sc.IconLocation = "C:\Windows\System32\shell32.dll,13"
$sc.Save()
Write-Host "Created: PCC - Setup GitHub.lnk"

# GitHub Pages URL shortcut (will work after deployment)
$sc2 = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\PCC - Live Site (GitHub Pages).lnk")
$sc2.TargetPath = "https://frenchbt79.github.io/project-command-center/"
$sc2.Description = "Open Project Command Center on GitHub Pages (works on any device)"
$sc2.IconLocation = "C:\Windows\System32\shell32.dll,14"
$sc2.Save()
Write-Host "Created: PCC - Live Site (GitHub Pages).lnk"

Write-Host "Done!"
