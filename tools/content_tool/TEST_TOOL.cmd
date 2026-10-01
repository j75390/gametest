@echo off
setlocal
cd /d "%~dp0"

where py >nul 2>&1
if %errorlevel%==0 (
    py -3 content_tool.py self-test
    goto :aftertest
)

where python >nul 2>&1
if %errorlevel%==0 (
    python content_tool.py self-test
    goto :aftertest
)

echo.
echo [ERROR] Python 3 was not found.
echo.
pause
exit /b 1

:aftertest
echo.
if %errorlevel%==0 (
    echo SELF-TEST PASSED.
) else (
    echo SELF-TEST FAILED.
)
echo.
pause
endlocal
