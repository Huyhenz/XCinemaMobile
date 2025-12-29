# Hướng dẫn cấu hình Internet cho Android Emulator

## Vấn đề
Máy ảo Android Emulator không có kết nối internet để phát trailer YouTube.

## Giải pháp

### 1. Kiểm tra máy host có internet
- Đảm bảo máy tính của bạn đã kết nối internet
- Mở trình duyệt và kiểm tra có thể truy cập YouTube không

### 2. Cấu hình Android Emulator

#### Cách 1: Sử dụng DNS của Google (Khuyến nghị)
1. Mở Android Emulator
2. Vào **Settings** (Cài đặt)
3. Chọn **Network & internet** (Mạng và Internet)
4. Chọn **Wi-Fi** hoặc **Mobile network**
5. Nhấn và giữ vào mạng hiện tại
6. Chọn **Modify network** (Sửa mạng)
7. Chọn **Show advanced options** (Hiện tùy chọn nâng cao)
8. Đặt **IP settings** thành **Static**
9. Đặt **DNS 1**: `8.8.8.8` (Google DNS)
10. Đặt **DNS 2**: `8.8.4.4` (Google DNS backup)
11. Lưu và khởi động lại emulator

#### Cách 2: Sử dụng lệnh ADB (Nhanh nhất)
Mở Command Prompt hoặc PowerShell và chạy:

```bash
# Kiểm tra emulator đang chạy
adb devices

# Thiết lập DNS cho emulator
adb shell "settings put global private_dns_mode hostname"
adb shell "settings put global private_dns_specifier 8.8.8.8"

# Hoặc đơn giản hơn, chỉ cần ping để test
adb shell ping -c 3 8.8.8.8
```

#### Cách 3: Cấu hình trong Android Studio
1. Mở **Android Studio**
2. Vào **Tools** > **Device Manager**
3. Chọn emulator của bạn
4. Nhấn **Edit** (biểu tượng bút chì)
5. Trong tab **Advanced Settings**
6. Tìm **Network** và chọn:
   - **NAT** (mặc định - thường hoạt động tốt)
   - Hoặc **Bridge** nếu NAT không hoạt động

### 3. Kiểm tra kết nối trong Emulator

Mở trình duyệt trong emulator và truy cập:
- `https://www.google.com` - Kiểm tra internet cơ bản
- `https://www.youtube.com` - Kiểm tra YouTube

Hoặc mở **Terminal** trong emulator và chạy:
```bash
ping -c 3 google.com
ping -c 3 youtube.com
```

### 4. Xử lý lỗi thường gặp

#### Lỗi: "Network is unreachable"
**Giải pháp:**
```bash
# Reset network settings trong emulator
adb shell "settings delete global private_dns_mode"
adb shell "settings delete global private_dns_specifier"

# Khởi động lại emulator
```

#### Lỗi: Emulator không có Wi-Fi icon
**Giải pháp:**
1. Đóng emulator
2. Xóa cache: `File` > `Invalidate Caches / Restart`
3. Khởi động lại emulator

#### Lỗi: Firewall chặn kết nối
**Giải pháp:**
- Tắt Windows Firewall tạm thời để test
- Hoặc thêm exception cho Android Emulator trong Firewall

### 5. Test trong app

Sau khi cấu hình xong:
1. Chạy app: `flutter run`
2. Vào trang chi tiết phim
3. Nhấn "Xem Trailer"
4. Video sẽ tự động phát nếu có internet

### 6. Fallback trong app

Nếu không có internet, app sẽ:
- Hiển thị thông báo lỗi rõ ràng
- Cung cấp nút "Mở trên trình duyệt" để mở YouTube bên ngoài
- Có nút "Thử lại" để kiểm tra lại kết nối

## Lưu ý quan trọng

1. **Máy ảo cần internet để phát YouTube video** - Không thể phát offline
2. **DNS của Google (8.8.8.8)** thường hoạt động tốt nhất
3. **NAT mode** là chế độ mặc định và thường đủ dùng
4. Nếu vẫn không được, thử **Cold Boot** emulator (khởi động lại hoàn toàn)

## Kiểm tra nhanh

Chạy lệnh này để test internet trong emulator:
```bash
adb shell "ping -c 3 8.8.8.8 && echo 'Internet OK' || echo 'No Internet'"
```

Nếu thấy "Internet OK" thì emulator đã có internet!

