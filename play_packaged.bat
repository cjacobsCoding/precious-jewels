@echo off
setlocal

set "PORT=8060"
set "PACKAGED_DIR=%~dp0packaged"
set "GAME_URL=http://127.0.0.1:%PORT%/Precious%%20Jewels.html"

if not exist "%PACKAGED_DIR%\Precious Jewels.html" (
    echo Could not find "%PACKAGED_DIR%\Precious Jewels.html".
    echo Export the Web build to the packaged folder first.
    pause
    exit /b 1
)

where py >nul 2>nul
if %errorlevel% equ 0 (
    set "PY_CMD=py"
) else (
    where python >nul 2>nul
    if %errorlevel% equ 0 (
        set "PY_CMD=python"
    ) else (
        echo Python was not found. Install Python or the Python Launcher for Windows.
        pause
        exit /b 1
    )
)

echo Serving packaged build at %GAME_URL%
echo Keep this window open while playtesting. Press Ctrl+C to stop the server.
start "" "%GAME_URL%"
cd /d "%PACKAGED_DIR%"
%PY_CMD% -m http.server %PORT% --bind 127.0.0.1
