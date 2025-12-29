@echo off
echo ========================================
echo   Cau hinh Internet cho Android Emulator
echo ========================================
echo.

REM Kiểm tra ADB có sẵn không
where adb >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] ADB khong tim thay!
    echo Vui long cai dat Android SDK hoac them ADB vao PATH
    pause
    exit /b 1
)

echo [1/4] Kiem tra emulator dang chay...
adb devices
echo.

echo [2/4] Thiet lap DNS Google (8.8.8.8)...
adb shell "settings put global private_dns_mode off"
adb shell "settings put global private_dns_specifier 8.8.8.8"
echo.

echo [3/4] Kiem tra ket noi internet...
adb shell "ping -c 3 8.8.8.8"
echo.

echo [4/4] Test ket noi den YouTube...
adb shell "ping -c 2 youtube.com"
echo.

echo ========================================
echo   Hoan thanh!
echo ========================================
echo.
echo Neu thay "ping: unknown host" thi emulator chua co internet.
echo Thu cac cach sau:
echo   1. Khoi dong lai emulator (Cold Boot)
echo   2. Kiem tra may host co internet khong
echo   3. Xem file ANDROID_EMULATOR_INTERNET_SETUP.md de biet them chi tiet
echo.
pause

