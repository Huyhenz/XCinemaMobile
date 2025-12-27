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
```

**Lưu ý**: 
- ⚠️ **KHÔNG** commit file `.env` vào Git (đã thêm vào `.gitignore`)
- ✅ File `.env.example` sẽ được commit (không có thông tin nhạy cảm)

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

## 📋 Checklist

- [ ] Đã copy `.env.example` thành `.env`
- [ ] Đã điền PayPal Client ID
- [ ] Đã điền PayPal Secret
- [ ] Đã set `PAYPAL_MODE=sandbox` (để test)
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

