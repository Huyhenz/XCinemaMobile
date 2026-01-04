# 🚀 Hướng Dẫn Tích Hợp Checkout.vn

Checkout.vn là cổng thanh toán trung gian hỗ trợ nhiều phương thức thanh toán: **ZaloPay, VNPay, MoMo, và nhiều cổng khác**. Bạn **KHÔNG CẦN** đăng ký từng cổng riêng lẻ!

## ✅ Ưu Điểm Checkout.vn

- ✅ **KHÔNG cần đăng ký ZaloPay trực tiếp** - Checkout.vn xử lý tất cả
- ✅ Hỗ trợ nhiều cổng thanh toán: ZaloPay, VNPay, MoMo, v.v.
- ✅ API đơn giản, tích hợp nhanh (1-2 giờ)
- ✅ Có sandbox để test miễn phí
- ✅ Hỗ trợ tốt, tài liệu đầy đủ

## 📋 Mục Lục

1. [Đăng Ký Tài Khoản](#1-đăng-ký-tài-khoản)
2. [Tạo Website](#2-tạo-website)
3. [Lấy API Credentials](#3-lấy-api-credentials)
4. [Cấu Hình Trong Project](#4-cấu-hình-trong-project)
5. [Test Thanh Toán](#5-test-thanh-toán)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. Đăng Ký Tài Khoản

### Bước 1: Truy Cập Checkout.vn

1. Truy cập: **https://checkout.vn**
2. Click **"Đăng ký"** hoặc **"Tạo tài khoản"**

### Bước 2: Điền Thông Tin

Điền các thông tin cần thiết:
- **Email**: Email của bạn
- **Mật khẩu**: Tạo mật khẩu mạnh
- **Số điện thoại**: SĐT của bạn
- **Tên công ty/Website**: Tên project của bạn (ví dụ: "XCinema")

### Bước 3: Xác Thực Email

1. Kiểm tra email để xác thực tài khoản
2. Click vào link xác thực trong email
3. Hoàn tất đăng ký

---

## 2. Tạo Website

Sau khi đăng nhập, bạn cần tạo một Website để quản lý giao dịch:

### Bước 1: Vào Mục Website

1. Đăng nhập vào **https://checkout.vn**
2. Vào menu **"Website"** hoặc **"Quản lý Website"**
3. Click **"+ Thêm mới"** hoặc **"Tạo Website mới"**

### Bước 2: Điền Thông Tin Website

Điền các thông tin:
- **Tên website**: Tên project của bạn (ví dụ: "XCinema Mobile")
- **Địa chỉ website**: URL của app/website (ví dụ: `https://xcinema.app`)
- **Mô tả**: Mô tả ngắn về website/app

### Bước 3: Lưu Website

1. Click **"Lưu"** hoặc **"Tạo"**
2. Website ID sẽ được tạo tự động (bạn sẽ cần ID này sau)

---

## 3. Lấy API Credentials

### Bước 1: Vào Phần Cài Đặt

1. Đăng nhập vào **https://checkout.vn**
2. Vào menu **"Cài đặt"** hoặc **"Settings"**
3. Chọn **"API key"** hoặc **"API Keys"**

### Bước 2: Lấy API Key và API Token

Bạn sẽ thấy:
- **API Key**: Một chuỗi ký tự dài (ví dụ: `ck_live_xxxxxxxxxxxxx`)
- **API Token**: Một chuỗi ký tự dài khác (ví dụ: `sk_live_xxxxxxxxxxxxx`)

**Lưu ý:**
- ⚠️ **KHÔNG** chia sẻ API Key và Token công khai
- ⚠️ **KHÔNG** commit vào Git
- ✅ Lưu vào file `.env` (đã có trong `.gitignore`)

### Bước 3: Lấy Website ID

1. Vào menu **"Website"**
2. Chọn website bạn vừa tạo
3. Copy **Website ID** (thường là số hoặc chuỗi ký tự)

---

## 4. Cấu Hình Trong Project

### Bước 1: Cập Nhật File `.env`

Mở file `.env` và thêm các thông tin sau:

```env
# Checkout.vn Configuration
CHECKOUT_API_KEY=your_checkout_api_key_here
CHECKOUT_API_TOKEN=your_checkout_api_token_here
CHECKOUT_WEBSITE_ID=your_checkout_website_id_here
CHECKOUT_RETURN_URL=https://xcinema.app/checkout/callback
CHECKOUT_CANCEL_URL=https://xcinema.app/checkout/cancel
```

**Ví dụ thực tế:**
```env
# Checkout.vn Configuration
CHECKOUT_API_KEY=ck_live_abc123xyz789
CHECKOUT_API_TOKEN=sk_live_def456uvw012
CHECKOUT_WEBSITE_ID=12345
CHECKOUT_RETURN_URL=https://xcinema.app/checkout/callback
CHECKOUT_CANCEL_URL=https://xcinema.app/checkout/cancel
```

**Lưu ý:**
- Thay `your_checkout_api_key_here` bằng API Key thật từ Checkout.vn
- Thay `your_checkout_api_token_here` bằng API Token thật
- Thay `your_checkout_website_id_here` bằng Website ID thật
- Return URL và Cancel URL có thể dùng URL mặc định (không cần thiết phải có thật)

### Bước 2: Kiểm Tra Code Đã Tích Hợp

Code đã được tích hợp sẵn trong:
- ✅ `lib/services/payment_service.dart` - Service xử lý thanh toán
- ✅ `lib/screens/payment_screen.dart` - UI chọn phương thức thanh toán

**Payment Method:** `PaymentMethod.checkout`

### Bước 3: Chạy Ứng Dụng

```bash
flutter run
```

Khi chạy, kiểm tra console logs:
- `✅ Checkout.vn credentials found in .env` - Nếu thấy dòng này, credentials đã được load
- `📝 Using Checkout.vn: Website ID: [id]` - Website ID đã được load

---

## 5. Test Thanh Toán

### Bước 1: Chọn Checkout.vn Trong App

1. Mở ứng dụng
2. Chọn ghế và thanh toán
3. Trong màn hình thanh toán, chọn **"Checkout.vn"**
4. Click **"XÁC NHẬN THANH TOÁN"**

### Bước 2: Chọn Phương Thức Thanh Toán

WebView sẽ mở với trang Checkout.vn, bạn có thể chọn:
- **ZaloPay** - Thanh toán qua ZaloPay
- **VNPay** - Thanh toán qua VNPay
- **MoMo** - Thanh toán qua MoMo
- Và nhiều phương thức khác

### Bước 3: Hoàn Tất Thanh Toán

1. Chọn phương thức thanh toán (ví dụ: ZaloPay)
2. Đăng nhập và xác nhận thanh toán
3. Kiểm tra kết quả trong app

---

## 6. Troubleshooting

### Lỗi: "Checkout.vn chưa được cấu hình"

**Nguyên nhân:**
- Credentials chưa được thêm vào `.env`
- File `.env` chưa được load

**Giải pháp:**
1. Kiểm tra file `.env` có đúng tên không (có dấu chấm ở đầu)
2. Kiểm tra file `.env` có ở root project không
3. Kiểm tra credentials có đúng format không
4. Đảm bảo `main.dart` đã load `.env`:
   ```dart
   await dotenv.load(fileName: ".env");
   ```

### Lỗi: "Không thể tạo giao dịch Checkout.vn"

**Nguyên nhân:**
- API Key hoặc Token sai
- Website ID sai
- API endpoint không đúng

**Giải pháp:**
1. Kiểm tra API Key và Token trong `.env` có đúng không
2. Kiểm tra Website ID có đúng không
3. Xem console logs để biết lỗi cụ thể
4. Kiểm tra kết nối mạng

### Lỗi: "Payment URL not found in response"

**Nguyên nhân:**
- API response format không đúng
- Checkout.vn API đã thay đổi format

**Giải pháp:**
1. Xem console logs để xem response body
2. Kiểm tra tài liệu API mới nhất của Checkout.vn
3. Cập nhật code nếu cần (trong `_createCheckoutTransaction`)

### API Trả Về Lỗi 401 (Unauthorized)

**Nguyên nhân:**
- API Key hoặc Token không đúng
- Token đã hết hạn

**Giải pháp:**
1. Kiểm tra lại API Key và Token trong Checkout.vn dashboard
2. Tạo API Token mới nếu cần
3. Cập nhật lại trong `.env`

### API Trả Về Lỗi 400 (Bad Request)

**Nguyên nhân:**
- Thiếu hoặc sai parameters
- Website ID không tồn tại

**Giải pháp:**
1. Kiểm tra tất cả parameters có đầy đủ không
2. Kiểm tra Website ID có đúng không
3. Xem console logs để biết parameter nào sai

---

## 📚 Tài Liệu Tham Khảo

- **Checkout.vn**: https://checkout.vn
- **Tài liệu API**: https://help.checkout.vn/api-tao-giao-dich-moi.html
- **Hướng dẫn tích hợp**: https://help.checkout.vn/Huong-dan-tich-hop-cong-thanh-toan.html
- **API thông tin thanh toán**: https://help.checkout.vn/api-thong-tin-thanh-toan-cua-don-hang.html

---

## ⚠️ Lưu Ý Quan Trọng

1. **Bảo Mật Credentials**:
   - ❌ KHÔNG commit `.env` lên Git (đã có trong `.gitignore`)
   - ❌ KHÔNG chia sẻ API Key và Token công khai
   - ✅ Chỉ dùng credentials trong `.env` file

2. **Sandbox vs Production**:
   - Checkout.vn có sandbox để test
   - Dùng sandbox credentials khi test
   - Dùng production credentials khi ra mắt

3. **Return URL và Cancel URL**:
   - URL này không cần phải tồn tại thật
   - Checkout.vn sẽ redirect về URL này sau khi thanh toán
   - App sẽ detect URL pattern để biết kết quả thanh toán

4. **Phương Thức Thanh Toán**:
   - Checkout.vn hỗ trợ nhiều phương thức
   - Người dùng chọn phương thức trên trang Checkout.vn
   - Bạn không cần cấu hình từng phương thức riêng

---

## ✅ Checklist

Trước khi test, đảm bảo:

- [ ] Đã đăng ký tài khoản Checkout.vn
- [ ] Đã tạo Website trong Checkout.vn
- [ ] Đã lấy API Key, API Token, và Website ID
- [ ] Đã thêm credentials vào `.env`
- [ ] Đã kiểm tra `CHECKOUT_API_KEY` không rỗng
- [ ] Đã kiểm tra `CHECKOUT_API_TOKEN` không rỗng
- [ ] Đã kiểm tra `CHECKOUT_WEBSITE_ID` không rỗng
- [ ] Đã chạy `flutter run` và test thanh toán

---

## 🎯 Tóm Tắt Quy Trình

1. **Đăng ký** → https://checkout.vn
2. **Tạo Website** → Lấy Website ID
3. **Lấy API Keys** → Cài đặt → API key
4. **Thêm vào `.env`** → Cấu hình credentials
5. **Test** → Chạy app và test thanh toán

---

**Chúc bạn tích hợp thành công! 🎉**

Nếu gặp vấn đề, hãy xem phần Troubleshooting hoặc liên hệ hỗ trợ Checkout.vn.





