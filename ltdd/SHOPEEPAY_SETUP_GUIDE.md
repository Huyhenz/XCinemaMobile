# 🛍️ Hướng Dẫn Cấu Hình ShopeePay API

Hướng dẫn chi tiết để tích hợp ShopeePay API vào ứng dụng XCinema.

## 📋 Mục Lục

1. [Đăng Ký Tài Khoản ShopeePay](#1-đăng-ký-tài-khoản-shopeepay)
2. [Lấy Thông Tin API](#2-lấy-thông-tin-api)
3. [Cấu Hình Trong Ứng Dụng](#3-cấu-hình-trong-ứng-dụng)
4. [Kiểm Tra Tích Hợp](#4-kiểm-tra-tích-hợp)
5. [Xử Lý Callback](#5-xử-lý-callback)

---

## 1. Đăng Ký Tài Khoản ShopeePay

### Bước 1: Truy cập trang đối tác ShopeePay

1. Truy cập: https://shopeepay.vn/doi-tac/
2. Điền vào mẫu đăng ký hợp tác với các thông tin:
   - Tên công ty/doanh nghiệp
   - Email liên hệ
   - Số điện thoại
   - Mô tả về dịch vụ/sản phẩm
   - Website/ứng dụng của bạn

### Bước 2: Chờ phê duyệt

- Đội ngũ ShopeePay sẽ liên hệ để hướng dẫn các bước tiếp theo
- Bạn sẽ cần gửi các tài liệu kinh doanh và ký hợp đồng
- Quá trình này có thể mất vài ngày đến vài tuần

---

## 2. Lấy Thông Tin API

Sau khi được phê duyệt, bạn sẽ nhận được các thông tin sau:

### Thông Tin Cần Thiết:

1. **Client ID** (`SHOPEEPAY_CLIENT_ID`)
   - Mã định danh ứng dụng của bạn
   - Format: Chuỗi ký tự dài

2. **Secret Key** (`SHOPEEPAY_SECRET_KEY`)
   - Khóa bí mật để xác thực API
   - **QUAN TRỌNG**: Giữ bí mật, không chia sẻ công khai

3. **Merchant Ex ID** (`SHOPEEPAY_MERCHANT_EX_ID`)
   - Mã định danh merchant của bạn
   - Dùng để tạo đơn hàng

4. **Store Ex ID** (`SHOPEEPAY_STORE_EX_ID`)
   - Mã định danh cửa hàng của bạn
   - Dùng để tạo đơn hàng

5. **API Endpoints**:
   - **Sandbox (Test)**: `https://open-api-sandbox.shopee.vn`
   - **Production**: `https://open-api.shopee.vn`

---

## 3. Cấu Hình Trong Ứng Dụng

### Bước 1: Thêm Credentials vào file `.env`

Mở file `.env` trong thư mục gốc của project và thêm các dòng sau:

```env
# ShopeePay Configuration
SHOPEEPAY_CLIENT_ID=your_client_id_here
SHOPEEPAY_SECRET_KEY=your_secret_key_here
SHOPEEPAY_MERCHANT_EX_ID=your_merchant_ex_id_here
SHOPEEPAY_STORE_EX_ID=your_store_ex_id_here
SHOPEEPAY_MODE=sandbox
```

**Lưu ý:**
- Thay `your_client_id_here`, `your_secret_key_here`, v.v. bằng các giá trị thật từ ShopeePay
- Đặt `SHOPEEPAY_MODE=sandbox` khi test, `SHOPEEPAY_MODE=production` khi chạy thật

### Bước 2: Kiểm tra file `.env` đã được thêm vào `pubspec.yaml`

Đảm bảo file `.env` đã được khai báo trong `pubspec.yaml`:

```yaml
flutter:
  assets:
    - .env
```

### Bước 3: Chạy lại ứng dụng

```bash
flutter clean
flutter pub get
flutter run
```

---

## 4. Kiểm Tra Tích Hợp

### Kiểm tra trong Console Log

Khi khởi động ứng dụng, bạn sẽ thấy log như sau nếu cấu hình đúng:

```
✅ ShopeePay credentials found in .env
📝 ShopeePay Client ID: your_clien...
📝 ShopeePay Mode: sandbox
```

Nếu không thấy, sẽ có cảnh báo:

```
⚠️ ShopeePay credentials not found in .env (ShopeePay payment will use mock)
💡 To enable real ShopeePay payment, add SHOPEEPAY_CLIENT_ID, SHOPEEPAY_SECRET_KEY, SHOPEEPAY_MERCHANT_EX_ID, SHOPEEPAY_STORE_EX_ID to .env file
```

### Test Thanh Toán

1. Mở ứng dụng và chọn một bộ phim
2. Chọn ghế và chuyển đến màn hình thanh toán
3. Chọn **ShopeePay** làm phương thức thanh toán
4. Nếu cấu hình đúng:
   - Ứng dụng sẽ gọi API ShopeePay để tạo đơn hàng
   - Mở WebView với trang thanh toán thật từ ShopeePay
   - Sau khi thanh toán thành công, sẽ quay về màn hình thành công

### Nếu Chưa Có Credentials

- Ứng dụng sẽ tự động sử dụng **mock payment** (thanh toán mô phỏng)
- Bạn vẫn có thể test flow thanh toán nhưng không phải giao dịch thật

---

## 5. Xử Lý Callback

### Return URLs

ShopeePay sẽ redirect về các URL sau sau khi thanh toán:

- **Success URL**: `https://xcinema.app/shopee/success?transaction_id=...`
- **Cancel URL**: `https://xcinema.app/shopee/cancel`

### WebView Navigation Detection

Ứng dụng tự động phát hiện khi người dùng:
- Thanh toán thành công → Đóng WebView và hiển thị màn hình thành công
- Hủy thanh toán → Đóng WebView và hiển thị màn hình thất bại

### Verify Payment (Backend)

**QUAN TRỌNG**: Trong môi trường production, bạn cần:

1. **Tạo backend endpoint** để nhận webhook từ ShopeePay:
   ```
   POST https://your-backend.com/shopee/webhook
   ```

2. **Verify payment signature** từ ShopeePay để đảm bảo giao dịch hợp lệ

3. **Cập nhật trạng thái đơn hàng** trong database

4. **Gửi email xác nhận** cho khách hàng

---

## 🔒 Bảo Mật

### ⚠️ QUAN TRỌNG:

1. **KHÔNG commit file `.env` lên Git**
   - Thêm `.env` vào `.gitignore`
   - Chỉ lưu trữ credentials trên server production

2. **Secret Key phải được giữ bí mật**
   - Không chia sẻ trong code
   - Không log ra console trong production
   - Chỉ dùng trên backend khi cần verify payment

3. **Sử dụng HTTPS** cho tất cả API calls

4. **Validate payment** trên backend trước khi cập nhật database

---

## 📚 Tài Liệu Tham Khảo

- **Trang đối tác ShopeePay**: https://shopeepay.vn/doi-tac/
- **Hướng dẫn tích hợp**: https://help.haravan.com/docs/payments/payment-gateways/huong-dan-ket-noi-thanh-toan-online-qua-shopeepay/
- **Liên hệ hỗ trợ**: Qua email hoặc hotline từ ShopeePay

---

## ❓ Troubleshooting

### Lỗi: "Không thể kết nối với ShopeePay"

**Nguyên nhân có thể:**
- Credentials không đúng
- Network connection issue
- ShopeePay API đang bảo trì

**Giải pháp:**
1. Kiểm tra lại credentials trong `.env`
2. Kiểm tra kết nối internet
3. Thử lại sau vài phút

### Lỗi: "Không thể tạo đơn hàng ShopeePay"

**Nguyên nhân có thể:**
- Merchant Ex ID hoặc Store Ex ID không đúng
- Thiếu thông tin bắt buộc trong request

**Giải pháp:**
1. Kiểm tra lại `SHOPEEPAY_MERCHANT_EX_ID` và `SHOPEEPAY_STORE_EX_ID`
2. Xem log chi tiết trong console để biết lỗi cụ thể

### WebView không load được trang thanh toán

**Nguyên nhân có thể:**
- Payment URL không hợp lệ
- ShopeePay redirect về URL không đúng

**Giải pháp:**
1. Kiểm tra log để xem payment URL được tạo ra
2. Thử mở URL trong browser để kiểm tra
3. Liên hệ ShopeePay support nếu vấn đề vẫn tiếp tục

---

## ✅ Checklist

Trước khi deploy production, đảm bảo:

- [ ] Đã đăng ký và được phê duyệt bởi ShopeePay
- [ ] Đã thêm tất cả credentials vào `.env`
- [ ] Đã test thanh toán thành công trong sandbox mode
- [ ] Đã tạo backend endpoint để verify payment
- [ ] Đã cấu hình return URLs đúng
- [ ] Đã thêm `.env` vào `.gitignore`
- [ ] Đã chuyển sang `SHOPEEPAY_MODE=production`
- [ ] Đã test lại trong production mode

---

**Chúc bạn tích hợp thành công! 🎉**

