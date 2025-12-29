#!/bin/bash

echo "========================================"
echo "  Cấu hình Internet cho Android Emulator"
echo "========================================"
echo ""

# Kiểm tra ADB có sẵn không
if ! command -v adb &> /dev/null; then
    echo "[ERROR] ADB không tìm thấy!"
    echo "Vui lòng cài đặt Android SDK hoặc thêm ADB vào PATH"
    exit 1
fi

echo "[1/4] Kiểm tra emulator đang chạy..."
adb devices
echo ""

echo "[2/4] Thiết lập DNS Google (8.8.8.8)..."
adb shell "settings put global private_dns_mode off"
adb shell "settings put global private_dns_specifier 8.8.8.8"
echo ""

echo "[3/4] Kiểm tra kết nối internet..."
adb shell "ping -c 3 8.8.8.8"
echo ""

echo "[4/4] Test kết nối đến YouTube..."
adb shell "ping -c 2 youtube.com"
echo ""

echo "========================================"
echo "  Hoàn thành!"
echo "========================================"
echo ""
echo "Nếu thấy 'ping: unknown host' thì emulator chưa có internet."
echo "Thử các cách sau:"
echo "  1. Khởi động lại emulator (Cold Boot)"
echo "  2. Kiểm tra máy host có internet không"
echo "  3. Xem file ANDROID_EMULATOR_INTERNET_SETUP.md để biết thêm chi tiết"
echo ""


