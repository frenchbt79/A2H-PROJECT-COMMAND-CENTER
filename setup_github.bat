@echo off
title Project Command Center - GitHub Setup
echo ==========================================
echo   Project Command Center - GitHub Setup
echo ==========================================
echo.

cd /d "%~dp0"
set "GH=%ProgramFiles%\GitHub CLI\gh.exe"

:: ── Step 1: Check GitHub CLI auth ──
echo [Step 1] Checking GitHub CLI authentication...
"%GH%" auth status >nul 2>&1
if errorlevel 1 (
    echo    Not logged in. Starting GitHub login...
    echo    A browser window will open. Follow the prompts.
    echo.
    "%GH%" auth login --web
    if errorlevel 1 (
        echo [ERROR] GitHub authentication failed.
        goto :error
    )
)
echo    [OK] Authenticated with GitHub
echo.

:: ── Step 2: Init git repo ──
if exist ".git" (
    echo [Step 2] Git repo already initialized - skipping
) else (
    echo [Step 2] Initializing git repository...
    git init -b main
    if errorlevel 1 goto :error
)
echo.

:: ── Step 3: Stage and commit ──
echo [Step 3] Staging all files...
git add -A
if errorlevel 1 goto :error

git diff --cached --quiet 2>nul
if errorlevel 1 (
    echo    Committing...
    git commit -m "Initial commit - Project Command Center"
    if errorlevel 1 goto :error
) else (
    echo    [OK] Nothing new to commit
)
echo.

:: ── Step 4: Create GitHub repo and push ──
echo [Step 4] Creating GitHub repository...
"%GH%" repo create project-command-center --public --source=. --push --description "Project Command Center - Flutter project management dashboard" 2>nul
if errorlevel 1 (
    echo    Repo may already exist. Trying to set remote and push...
    git remote remove origin 2>nul
    "%GH%" repo view frenchbt79/project-command-center >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Could not create or find repo.
        goto :error
    )
    git remote add origin https://github.com/frenchbt79/project-command-center.git
    git push -u origin main
    if errorlevel 1 goto :error
)
echo    [OK] Code pushed to GitHub
echo.

:: ── Step 5: Enable GitHub Pages ──
echo [Step 5] Enabling GitHub Pages (Actions deployment)...
"%GH%" api repos/frenchbt79/project-command-center/pages -X POST -f "build_type=workflow" -f "source[branch]=main" -f "source[path]=/" 2>nul
if errorlevel 1 (
    echo    Pages may already be enabled or needs manual setup.
    echo    Go to: https://github.com/frenchbt79/project-command-center/settings/pages
    echo    Set Source to "GitHub Actions"
)
echo.

:: ── Done ──
echo ==========================================
echo   SETUP COMPLETE!
echo ==========================================
echo.
echo   GitHub Repo:
echo     https://github.com/frenchbt79/project-command-center
echo.
echo   GitHub Pages URL (live in ~3-5 min):
echo     https://frenchbt79.github.io/project-command-center/
echo.
echo   To test on iPhone:
echo     Open the Pages URL in Safari, then
echo     tap Share ^> "Add to Home Screen"
echo.
echo ==========================================
pause
goto :eof

:error
echo.
echo [ERROR] Something went wrong. See above for details.
echo.
pause
