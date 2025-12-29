# Cấu hình Internet cho Android Emulator - Hướng dẫn chi tiết

## ⚠️ Tình trạng hiện tại
DNS đã được thiết lập thành công (`8.8.8.8`), nhưng emulator vẫn chưa có kết nối internet (ping không thành công).

## 🔧 Giải pháp

### Cách 1: Khởi động lại Emulator với Cold Boot (Khuyến nghị)

1. **Đóng emulator hiện tại**
   - Trong Android Studio: `Device Manager` > Chọn emulator > `Stop`
   - Hoặc đóng cửa sổ emulator

2. **Cold Boot (Khởi động lại hoàn toàn)**
   - Trong Android Studio: `Device Manager` > Chọn emulator > `Cold Boot Now`
   - Hoặc: `Device Manager` > Chọn emulator > Menu (3 chấm) > `Cold Boot Now`

3. **Chờ emulator khởi động xong** (có thể mất 1-2 phút)

4. **Chạy lại script cấu hình:**
   ```bash
   setup_emulator_internet.bat
   ```

### Cách 2: Cấu hình trong Android Studio

1. Mở **Android Studio**
2. Vào **Tools** > **Device Manager**
3. Chọn emulator của bạn
4. Nhấn **Edit** (biểu tượng bút chì)
5. Trong tab **Show Advanced Settings**
6. Tìm phần **Network**:
   - Chọn **NAT** (mặc định - thường hoạt động tốt)
   - Hoặc thử **Bridge** nếu NAT không hoạt động
7. Nhấn **Finish** và khởi động lại emulator

### Cách 3: Kiểm tra máy host có internet không

1. Mở trình duyệt trên máy tính
2. Truy cập: `https://www.google.com`
3. Nếu không truy cập được → Máy host không có internet
4. Kết nối internet cho máy host trước

### Cách 4: Cấu hình Proxy (Nếu dùng proxy)

Nếu máy bạn dùng proxy để truy cập internet:

1. Mở **Settings** trong emulator
2. Vào **Network & internet** > **Wi-Fi**
3. Nhấn và giữ vào mạng hiện tại > **Modify network**
4. **Show advanced options**
5. Đặt **Proxy**: `Manual`
6. Nhập thông tin proxy của máy host

### Cách 5: Kiểm tra Firewall

Windows Firewall có thể chặn kết nối của emulator:

1. Mở **Windows Defender Firewall**
2. Vào **Allow an app or feature through Windows Defender Firewall**
3. Tìm và bật **Android Emulator** hoặc **adb.exe**
4. Hoặc tạm thời tắt Firewall để test

## ✅ Kiểm tra sau khi cấu hình

Sau khi thực hiện các bước trên, kiểm tra lại:

```bash
# Chạy script kiểm tra
setup_emulator_internet.bat
```

Hoặc thủ công:
```bash
adb shell "ping -c 3 8.8.8.8"
```

Nếu thấy `0% packet loss` → ✅ Emulator đã có internet!

## 🎬 Test trong app

1. Chạy app: `flutter run`
2. Vào trang chi tiết phim
3. Nhấn "Xem Trailer"
4. Video sẽ phát nếu có internet

## 📝 Lưu ý

- **Emulator cần internet để phát YouTube video** - Không thể phát offline
- **Cold Boot** thường giải quyết được hầu hết vấn đề về network
- Nếu vẫn không được, thử tạo emulator mới với cấu hình mặc định

## 🆘 Vẫn không được?

Nếu đã thử tất cả các cách trên mà vẫn không có internet:

1. Tạo emulator mới:
   - `Device Manager` > `Create Device`
   - Chọn device > `Next`
   - Chọn system image (khuyến nghị: API 33 hoặc 34)
   - `Finish`
   - Chạy emulator mới và test lại

2. Hoặc test trên thiết bị thật:
   - Kết nối điện thoại Android qua USB
   - Bật USB Debugging
   - Chạy `flutter run` và chọn thiết bị thật


