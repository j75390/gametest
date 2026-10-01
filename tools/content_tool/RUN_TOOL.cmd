@echo off
setlocal
cd /d "%~dp0"

where py >nul 2>&1
if %errorlevel%==0 (
    py -3 content_tool.py serve
    goto :afterrun
)

where python >nul 2>&1
if %errorlevel%==0 (
    python content_tool.py serve
    goto :afterrun
)

echo.
echo [ERROR] Python 3 was not found.
echo Install Python 3 and enable "Add Python to PATH".
echo.
pause
exit /b 1

:afterrun
if not %errorlevel%==0 (
    echo.
    echo [ERROR] Content Tool exited with an error.
    echo Run TEST_TOOL.cmd to diagnose the problem.
    echo.
    pause
)
endlocal
