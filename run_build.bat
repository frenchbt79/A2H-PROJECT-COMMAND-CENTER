@echo off
set "PATH=C:\Program Files\Git\cmd;C:\Users\bfren\flutter\bin;%PATH%"
cd /d "C:\Users\bfren\Desktop\All Apps\Project Dashboard\project_command_center"
flutter build windows --debug > build_log.txt 2>&1
