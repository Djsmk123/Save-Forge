# Game Save Manager - Run as Administrator
# This script runs the Flutter app with administrator privileges

Write-Host "Starting Game Save Manager with Administrator privileges..." -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Running as administrator. Building and running Flutter app..." -ForegroundColor Green
Write-Host ""

# Navigate to project directory
Set-Location $PSScriptRoot

# Clean project
Write-Host "Cleaning project..." -ForegroundColor Cyan
flutter clean

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Cyan
flutter pub get

# Build for Windows
Write-Host "Building for Windows..." -ForegroundColor Cyan
flutter build windows

# Run the app
Write-Host "Running Game Save Manager..." -ForegroundColor Green
flutter run -d windows

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 