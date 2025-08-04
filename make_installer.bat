@echo off
setlocal enabledelayedexpansion

echo 📦 Starting installer creation...

REM Step 0: Set root path
set "ROOT_PATH=%cd%"

REM Step 1: Extract version from pubspec.yaml
for /f "tokens=2 delims=: " %%i in ('findstr /r "version:" pubspec.yaml') do (
    set version=%%i
    goto :found_version
)
echo ❌ Could not extract version from pubspec.yaml
exit /b 1

:found_version
echo 📦 Detected version: !version!

REM Step 2: Build Flutter app in separate terminal
echo 🔨 Building Flutter app in separate terminal...
start "Flutter Build" cmd /k "flutter build windows && echo Build completed successfully! && pause"
echo ⏳ Please complete the build in the new terminal window, then press any key to continue...
pause

REM Step 3: Check if build directory exists
if not exist "build\windows\x64\runner\Release" (
    echo ❌ Build directory not found. Please ensure Flutter build completed successfully.
    exit /b 1
)

REM Step 4: Create temporary ISS file
echo 🔧 Creating installer template...
powershell -Command ^
    "$tempFile = [System.IO.Path]::GetTempFileName() + '.iss';" ^
    "$content = Get-Content 'app_installer_window.iss' -Raw;" ^
    "$content = $content -replace '__VERSION__', '%version%';" ^
    "$content = $content -replace '__ROOT_PATH__', '%ROOT_PATH%';" ^
    "Set-Content $tempFile -Value $content;" ^
    "Write-Output $tempFile" > temp_file_path.txt

set /p temp_iss=<temp_file_path.txt
del temp_file_path.txt

REM Step 5: Compile installer
set iscc="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if not exist %iscc% (
    echo ❌ ISCC.exe not found at %iscc%
    exit /b 1
)

echo 🔨 Compiling installer...
%iscc% "!temp_iss!"
if %errorlevel% neq 0 (
    echo ❌ Inno Setup compilation failed
    exit /b 1
)

REM Step 6: Cleanup
if exist "!temp_iss!" del "!temp_iss!"

echo ✅ Installer created successfully!
pause 