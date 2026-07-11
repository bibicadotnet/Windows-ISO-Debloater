@echo off
setlocal EnableDelayedExpansion

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% equ 0 goto :admin
echo Requesting Administrator privileges...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b
:admin

cd /d "%~dp0"

set "ISO_NAME=en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso"
set "ISO_URL=https://windows.timefa.de/10/ltsc/en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso"

:download_iso
:: 1. Download original ISO if it does not exist
if exist "%ISO_NAME%" goto :iso_exists
echo Downloading Windows 10 IoT Enterprise LTSC 2021 ISO...
echo URL: %ISO_URL%
powershell -NoProfile -Command "Write-Host 'Downloading ISO file, please wait...' -ForegroundColor Cyan; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%ISO_URL%', '%ISO_NAME%')"
:iso_exists

:: Verify ISO exists
if exist "%ISO_NAME%" goto :verify_hash
echo Error: ISO file "%ISO_NAME%" was not downloaded successfully.
echo Retrying download in 5 seconds...
timeout /t 5 >nul
goto :download_iso

:verify_hash
echo Verifying SHA-256 checksum of %ISO_NAME%...
powershell -NoProfile -Command "$expected = 'a0334f31ea7a3e6932b9ad7206608248f0bd40698bfb8fc65f14fc5e4976c160'; Write-Host 'Calculating SHA-256...' -ForegroundColor Cyan; $hash = (Get-FileHash -Path '%ISO_NAME%' -Algorithm SHA256).Hash; if ($hash.ToLower() -eq $expected.ToLower()) { Write-Host 'SHA-256 checksum verified successfully' -ForegroundColor Green; exit 0 } else { Write-Host ('SHA-256 mismatch. Found: ' + $hash) -ForegroundColor Red; exit 1 }"

if !errorlevel! equ 0 goto :hash_ok
echo SHA-256 verification failed. Expected: a0334f31ea7a3e6932b9ad7206608248f0bd40698bfb8fc65f14fc5e4976c160
echo Deleting corrupted/incomplete ISO file and retrying download...
del /f /q "%ISO_NAME%"
timeout /t 3 >nul
goto :download_iso

:hash_ok

:: 2. Run the isoDebloaterScript.ps1 with automated parameters
echo Running Windows ISO Debloater...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0isoDebloaterScript.ps1" ^
    -noPrompt ^
    -isoPath "%~dp0%ISO_NAME%" ^
    -winEdition "Windows 10 IoT Enterprise LTSC" ^
    -outputISO "Win10.IoT.LTSC.iso" ^
    -AppxRemove "yes" ^
    -CapabilitiesRemove "yes" ^
    -OnedriveRemove "yes" ^
    -EDGERemove "no" ^
    -AIRemove "yes" ^
    -TPMBypass "no" ^
    -UserFoldersEnable "yes" ^
    -DriverIntegrate "no" ^
    -UpdateIntegrate "yes" ^
    -ESDConvert "yes" ^
    -useOscdimg "yes"

echo Completed!
pause
