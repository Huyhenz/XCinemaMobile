# Hướng Dẫn Tạo và Cấu Hình File .env

## 📁 Thông Tin File .env

### Tên File
- **Tên chính xác**: `.env` (có dấu chấm ở đầu)
- **File template**: `.env.example` (đã có sẵn trong project)

### Vị Trí Đặt File
Đặt file `.env` ở **root của project** (cùng cấp với `pubspec.yaml`):

```
ltdd/
├── .env                 ← Đặt file ở đây
├── .env.example         ← File template (đã có)
├── pubspec.yaml
├── lib/
├── android/
└── ...
```

## 🔧 Cách Tạo File .env

### Cách 1: Copy từ .env.example (Khuyến nghị)

1. **Mở terminal/command prompt** tại thư mục root của project
2. **Copy file**:
   ```bash
   # Windows (PowerShell)
   Copy-Item .env.example .env
   
   # Windows (CMD)
   copy .env.example .env
   
   # Mac/Linux
   cp .env.example .env
   ```
3. **Mở file `.env`** bằng text editor (VS Code, Notepad++, etc.)
4. **Thay thế** các giá trị `YOUR_..._HERE` bằng thông tin thật của bạn

### Cách 2: Tạo File Mới Thủ Công

1. **Tạo file mới** tên `.env` ở root project
2. **Copy nội dung** từ `.env.example`
3. **Điền thông tin** PayPal credentials của bạn

### Cách 3: Tạo File Trong VS Code

1. Mở VS Code tại root project
2. Nhấn **Ctrl + N** (hoặc File → New File)
3. **Lưu file** với tên `.env` (quan trọng: có dấu chấm ở đầu)
4. Copy nội dung từ `.env.example` và điền thông tin

## 📝 Nội Dung File .env

Sau khi tạo, file `.env` của bạn sẽ trông như thế này:

```env
# PayPal Sandbox Credentials
PAYPAL_CLIENT_ID=AeA1QIZXiflr1_-...  # Client ID từ PayPal Dashboard
PAYPAL_SECRET=EDrOnXQqL...           # Secret từ PayPal Dashboard
PAYPAL_MODE=sandbox                  # 'sandbox' để test, 'live' cho production

# SMTP Configuration (Cho Email Xác Nhận Đặt Vé)
SMTP_HOST=smtp.gmail.com             # SMTP server (Gmail: smtp.gmail.com)
SMTP_PORT=587                        # Port (Gmail: 587 cho TLS, 465 cho SSL)
SMTP_USERNAME=your-email@gmail.com   # Email gửi đi
SMTP_PASSWORD=your-app-password      # App Password (KHÔNG phải mật khẩu thường)
SMTP_FROM_EMAIL=your-email@gmail.com # Email hiển thị trong "From"
SMTP_FROM_NAME=XCinema               # Tên hiển thị trong "From"
```

**Lưu ý**: 
- ⚠️ **KHÔNG** commit file `.env` vào Git (đã thêm vào `.gitignore`)
- ✅ File `.env.example` sẽ được commit (không có thông tin nhạy cảm)
- 📧 **SMTP là tùy chọn**: Nếu không cấu hình SMTP, app vẫn hoạt động bình thường nhưng sẽ không gửi email xác nhận

## 🔒 Bảo Mật - Thêm vào .gitignore

File `.env` đã được thêm vào `.gitignore` tự động. Kiểm tra bằng cách:

1. Mở file `.gitignore` ở root project
2. Tìm dòng:
   ```
   # Environment variables (chứa credentials nhạy cảm)
   .env
   .env.local
   .env.*.local
   ```

Nếu chưa có, thêm vào cuối file `.gitignore`:

```gitignore
# Environment variables (chứa credentials nhạy cảm)
.env
.env.local
.env.*.local
```

## ⚙️ Load .env trong Code

File `main.dart` đã được cập nhật để load `.env` tự động:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: ".env");
  
  // ... rest of code
}
```

## ✅ Kiểm Tra .env Đã Hoạt Động

Sau khi tạo file `.env`, test bằng cách:

1. **Chạy app**:
   ```bash
   flutter run
   ```

2. **Kiểm tra log**: Nếu có lỗi về missing `.env`, kiểm tra:
   - File `.env` có đúng tên không (có dấu chấm ở đầu)
   - File `.env` có ở root project không
   - Nội dung file có đúng format không

## 🚨 Lưu Ý Quan Trọng

1. **KHÔNG** commit file `.env` vào Git
2. **KHÔNG** chia sẻ file `.env` với người khác
3. **KHÔNG** đặt credentials trực tiếp trong code
4. **LUÔN** sử dụng `.env` để lưu thông tin nhạy cảm
5. File `.env.example` là template, **KHÔNG** chứa thông tin thật

## 📧 Cấu Hình SMTP Cho Email Xác Nhận

### Tại Sao Cần SMTP?
Khi người dùng đặt vé thành công, hệ thống sẽ tự động gửi email xác nhận đến email của họ. Để gửi email, bạn cần cấu hình SMTP.

### Cấu Hình Gmail (Khuyến Nghị)

1. **Bật 2-Step Verification** cho tài khoản Gmail:
   - Vào: https://myaccount.google.com/security
   - Bật "2-Step Verification"

2. **Tạo App Password**:
   - Vào: https://myaccount.google.com/apppasswords
   - Chọn "Mail" và "Other (Custom name)"
   - Nhập tên: "XCinema App"
   - Copy mật khẩu 16 ký tự được tạo (ví dụ: `abcd efgh ijkl mnop`)

3. **Thêm vào file `.env`**:
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=your-email@gmail.com
   SMTP_PASSWORD=abcdefghijklmnop  # App Password (bỏ khoảng trắng)
   SMTP_FROM_EMAIL=your-email@gmail.com
   SMTP_FROM_NAME=XCinema
   ```

### Cấu Hình Email Khác

**Outlook/Hotmail:**
```env
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
```

**Yahoo:**
```env
SMTP_HOST=smtp.mail.yahoo.com
SMTP_PORT=587
```

**Custom SMTP Server:**
```env
SMTP_HOST=mail.yourdomain.com
SMTP_PORT=587  # hoặc 465 cho SSL
```

### Kiểm Tra Email Đã Gửi

Sau khi cấu hình SMTP:
1. Đặt vé thành công
2. Kiểm tra màn hình "Thanh toán thành công" - sẽ hiển thị trạng thái email
3. Nếu email gửi thành công: "✅ Email xác nhận đã được gửi"
4. Nếu email không gửi được: "⚠️ Email xác nhận chưa được gửi" + lý do

### Lưu Ý Quan Trọng

- ⚠️ **Gmail**: Phải dùng **App Password**, không dùng mật khẩu thường
- ⚠️ **App Password**: Là chuỗi 16 ký tự, không có khoảng trắng
- ✅ **Không bắt buộc**: Nếu không cấu hình SMTP, app vẫn hoạt động, chỉ không gửi email
- ✅ **Vé vẫn hợp lệ**: Dù email không gửi được, vé vẫn được lưu và hiển thị trong lịch sử đặt vé

## 📋 Checklist

- [ ] Đã copy `.env.example` thành `.env`
- [ ] Đã điền PayPal Client ID
- [ ] Đã điền PayPal Secret
- [ ] Đã set `PAYPAL_MODE=sandbox` (để test)
- [ ] Đã cấu hình SMTP (tùy chọn, để gửi email xác nhận)
- [ ] Đã kiểm tra `.env` có trong `.gitignore`
- [ ] Đã test app và không có lỗi về missing `.env`

## 🆘 Troubleshooting

### Lỗi: "File .env not found"
- Kiểm tra file có đúng tên `.env` (có dấu chấm ở đầu)
- Kiểm tra file có ở root project (cùng cấp với `pubspec.yaml`)
- Thử chạy `flutter clean` và `flutter pub get`

### Lỗi: "Environment variable not found"
- Kiểm tra tên biến trong `.env` có đúng không (không có khoảng trắng)
- Kiểm tra format: `KEY=value` (không có dấu cách quanh dấu `=`)
- Đảm bảo không có dấu ngoặc kép không cần thiết

### File .env bị commit vào Git
- Xóa file `.env` khỏi Git: `git rm --cached .env`
- Kiểm tra `.gitignore` có chứa `.env` không
- Commit lại: `git commit -m "Remove .env from tracking"`

### Email Không Gửi Được
- **Kiểm tra SMTP credentials**: Đảm bảo `SMTP_USERNAME` và `SMTP_PASSWORD` đã được điền trong `.env`
- **Gmail**: Phải dùng App Password, không dùng mật khẩu thường
- **Kiểm tra log**: Xem console log khi đặt vé để biết lý do email không gửi được
- **Màn hình thành công**: Sẽ hiển thị trạng thái email và lý do nếu không gửi được
- **Lưu ý**: Vé vẫn hợp lệ dù email không gửi được, có thể xem trong lịch sử đặt vé

