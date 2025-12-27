# PayPal Setup Checklist - Danh Sách Kiểm Tra

## ✅ Checklist Cấu Hình PayPal

### Bước 1: Đăng Ký & Tạo App
- [ ] Đã đăng ký tài khoản PayPal Developer
- [ ] Đã tạo Sandbox App
- [ ] Đã copy Client ID và Secret

### Bước 2: Cấu Hình Payment Capabilities

#### Payment Capabilities (Chọn những gì cần):
- [ ] ✅ **Payment links and buttons** - **BẮT BUỘC**
- [ ] ⚪ **Save payment methods** - Tùy chọn (để lưu thẻ)
- [ ] ⚪ **Subscriptions** - Không cần (trừ khi có gói đăng ký)
- [ ] ❌ **Invoicing** - KHÔNG CẦN
- [ ] ❌ **Payouts** - KHÔNG CẦN

#### Add-on Services (Chọn những gì cần):
- [ ] ✅ **Transaction search** - Nên chọn (để xem lịch sử)
- [ ] ✅ **Customer disputes** - Nên chọn (để xử lý tranh chấp)
- [ ] ❌ **Log in with PayPal** - KHÔNG CẦN

#### PayPal SDKs (Chọn những gì cần):
- [ ] ✅ **Mobile SDKs** - **BẮT BUỘC** (cho Flutter app)
- [ ] ❌ **JavaScript SDK v6** - KHÔNG CẦN (chỉ cho web)

### Bước 3: Lấy Credentials
- [ ] Đã copy Client ID
- [ ] Đã copy Secret
- [ ] Đã lưu vào file .env (chưa commit vào Git)

### Bước 4: Cài Đặt Packages
- [ ] Đã thêm `flutter_dotenv` vào pubspec.yaml
- [ ] Đã thêm `paypal_payment` (hoặc package khác) vào pubspec.yaml
- [ ] Đã chạy `flutter pub get`

### Bước 5: Cấu Hình Code
- [ ] Đã tạo file `.env` với credentials
- [ ] Đã thêm `.env` vào `.gitignore`
- [ ] Đã load `.env` trong `main.dart`
- [ ] Đã cập nhật `payment_service.dart`
- [ ] Đã cập nhật `payment_screen.dart` để truyền context

### Bước 6: Test
- [ ] Đã tạo Sandbox test account
- [ ] Đã test payment success
- [ ] Đã test payment cancel
- [ ] Đã kiểm tra database có lưu payment record

---

## 📝 Ghi Chú

### Tối Thiểu Cần Chọn:
1. **Payment links and buttons** (Payment Capabilities)
2. **Mobile SDKs** (PayPal SDKs)

### Nên Chọn Thêm:
1. **Save payment methods** (để lưu thẻ cho lần sau)
2. **Transaction search** (để xem lịch sử)
3. **Customer disputes** (để xử lý tranh chấp)

### Không Cần:
- Invoicing
- Payouts
- Log in with PayPal
- JavaScript SDK v6

---

## ⚠️ Lưu Ý

- Bạn **CÓ THỂ** chọn hết, nhưng **KHÔNG CẦN THIẾT**
- Chọn nhiều tính năng không ảnh hưởng đến hoạt động
- Chỉ cần đảm bảo có **"Payment links and buttons"** và **"Mobile SDKs"**
- Các tính năng khác có thể bật/tắt sau

