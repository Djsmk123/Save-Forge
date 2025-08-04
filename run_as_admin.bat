@echo off
echo Starting Game Save Manager with Administrator privileges...
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Already running as administrator.
) else (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo Building and running Flutter app...
echo.

REM Navigate to project directory
cd /d "%~dp0"

REM Clean and get dependencies
echo Cleaning project...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building for Windows...
flutter build windows

echo Running app...
flutter run -d windows

pause 