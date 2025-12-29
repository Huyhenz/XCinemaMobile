@echo off
chcp 65001 >nul
echo ========================================
echo   Cấu hình Internet cho Android Emulator
echo ========================================
echo.

REM Tìm ADB
set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB_PATH%" (
    echo [ERROR] Không tìm thấy ADB tại: %ADB_PATH%
    echo Vui lòng đảm bảo Android SDK đã được cài đặt.
    pause
    exit /b 1
)

echo [1/6] Kiểm tra emulator đang chạy...
"%ADB_PATH%" devices
echo.

echo [2/6] Thiết lập DNS Google (8.8.8.8)...
"%ADB_PATH%" shell "settings put global private_dns_mode off"
"%ADB_PATH%" shell "settings put global private_dns_specifier 8.8.8.8"
echo ✓ Đã thiết lập DNS
echo.

echo [3/6] Bật Wi-Fi và Data...
"%ADB_PATH%" shell "svc wifi enable"
"%ADB_PATH%" shell "svc data enable"
timeout /t 2 /nobreak >nul
echo ✓ Đã bật Wi-Fi và Data
echo.

echo [4/6] Tắt chế độ máy bay...
"%ADB_PATH%" shell "settings put global airplane_mode_on 0"
"%ADB_PATH%" shell "am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false"
echo ✓ Đã tắt chế độ máy bay
echo.

echo [5/6] Kiểm tra kết nối internet...
"%ADB_PATH%" shell "ping -c 3 8.8.8.8"
echo.

echo [6/6] Kiểm tra DNS đã được thiết lập...
"%ADB_PATH%" shell "settings get global private_dns_specifier"
echo.

echo ========================================
echo   Hoàn thành cấu hình!
echo ========================================
echo.
echo Nếu ping vẫn bị lỗi (100%% packet loss), hãy thử:
echo   1. Khởi động lại emulator (Cold Boot)
echo      - Android Studio ^> Device Manager ^> Chọn emulator ^> Cold Boot Now
echo   2. Kiểm tra máy tính có internet không
echo   3. Xem file EMULATOR_NETWORK_FIX.md để biết thêm chi tiết
echo.
echo Sau khi khởi động lại emulator, chạy lại script này.
echo.
pause


