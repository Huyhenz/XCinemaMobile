# 🚀 Hướng Dẫn Cấu Hình ZaloPay API

Hướng dẫn chi tiết để cấu hình ZaloPay API. Bạn có thể test **NGAY LẬP TỨC** với public sandbox credentials mà **KHÔNG CẦN** đăng ký!

## ✅ Tin Tốt: Có Thể Test Ngay Không Cần Đăng Ký!

ZaloPay cung cấp **public sandbox credentials** để bạn test tích hợp **NGAY LẬP TỨC** mà **KHÔNG CẦN**:
- ❌ Đăng ký tài khoản
- ❌ Đăng nhập
- ❌ Liên hệ hỗ trợ
- ❌ Tạo merchant account

**Code đã được cấu hình sẵn với public credentials!** Bạn chỉ cần chạy app và test ngay!

## 📋 Mục Lục

1. [Sử Dụng Public Sandbox Credentials (Không Cần Đăng Ký)](#1-sử-dụng-public-sandbox-credentials-không-cần-đăng-ký)
2. [Đăng Ký Tài Khoản Sandbox Riêng (Tùy Chọn)](#2-đăng-ký-tài-khoản-sandbox-riêng-tùy-chọn)
3. [Lấy API Credentials](#lấy-api-credentials)
4. [Cấu Hình Trong Project](#cấu-hình-trong-project)
5. [Test Thanh Toán](#test-thanh-toán)
6. [Troubleshooting](#troubleshooting)

---

## 1. Sử Dụng Public Sandbox Credentials (Không Cần Đăng Ký)

### ✅ Cách Dễ Nhất: Dùng Public Credentials

**Code đã được cấu hình sẵn!** Bạn **KHÔNG CẦN** làm gì cả, chỉ cần chạy app và test!

**Public Sandbox Credentials** (đã được cấu hình sẵn trong code):

#### Bộ 1 (Mặc định - đang dùng):
- **App ID**: `2554`
- **Key1**: `sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn`
- **Key2**: `trMrHtvjo6myautxDUiAcYsVtaeQ8nhf`
- **Base URL**: `https://sb-openapi.zalopay.vn`
- **Nguồn**: https://developers.zalopay.vn

#### Bộ 2 (Thay thế - nếu Bộ 1 không hoạt động):
- **App ID**: `554`
- **Key1**: `8NdU5pG5R2spGHGhyO99HN1OhD8IQJBn`
- **Key2**: `uUfsWgfLkRLzq6W2uNXTCxrfxs51auny`
- **Base URL**: `https://sb-openapi.zalopay.vn`
- **Nguồn**: https://developers.zalopay.vn

#### Bộ 3 (Thay thế - nếu Bộ 1 và 2 không hoạt động):
- **App ID**: `2553`
- **Key1**: `8NdU5pG5R2spGHGhyO99HN1OhD8IQJBn`
- **Key2**: `uUfsWgfLkRLzq6W2uNXTCxrfxs51auny`
- **Base URL**: `https://sb-openapi.zalopay.vn`
- **Nguồn**: https://developers.zalopay.vn

### 🚀 Bắt Đầu Test Ngay

1. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```

2. **Chọn ZaloPay** và test thanh toán

3. **Xong!** Không cần cấu hình gì thêm!

### 📝 Lưu Ý

- Public credentials có thể hoạt động hoặc không tùy theo chính sách của ZaloPay
- Nếu API thất bại, code sẽ tự động fallback về mock payment
- Để đảm bảo 100% hoạt động, bạn nên đăng ký tài khoản sandbox riêng (xem phần 2)

### 🔄 Thử Credentials Khác Nếu Bộ Hiện Tại Không Hoạt Động

Nếu bộ credentials mặc định (Bộ 1) không hoạt động, bạn có thể thử các bộ khác:

**Cách thử:**
1. Mở file `.env` trong project
2. Thêm hoặc cập nhật các dòng sau với credentials từ bộ khác:

**Ví dụ thử Bộ 2:**
```env
ZALOPAY_APP_ID=554
ZALOPAY_KEY1=8NdU5pG5R2spGHGhyO99HN1OhD8IQJBn
ZALOPAY_KEY2=uUfsWgfLkRLzq6W2uNXTCxrfxs51auny
ZALOPAY_MODE=sandbox
```

**Ví dụ thử Bộ 3:**
```env
ZALOPAY_APP_ID=2553
ZALOPAY_KEY1=8NdU5pG5R2spGHGhyO99HN1OhD8IQJBn
ZALOPAY_KEY2=uUfsWgfLkRLzq6W2uNXTCxrfxs51auny
ZALOPAY_MODE=sandbox
```

3. Lưu file và chạy lại app: `flutter run`
4. Test thanh toán lại

**Lưu ý:** Nếu tất cả các bộ credentials public đều không hoạt động, bạn cần đăng ký tài khoản sandbox riêng (xem phần 2 bên dưới).

---

## 2. Đăng Ký Tài Khoản Sandbox Riêng (Tùy Chọn)

Nếu bạn muốn có tài khoản sandbox riêng với quyền quản lý đầy đủ, hãy làm theo các bước sau:

### Bước 1: Truy Cập Trang Developer ZaloPay

### Bước 1: Truy Cập Trang Developer ZaloPay

1. Truy cập: **https://developers.zalopay.vn**
2. Tìm phần **"Bắt đầu"** hoặc **"Get Started"**
3. Click vào **"Đăng ký"** hoặc **"Tạo tài khoản"**

### Bước 2: Liên Hệ Hỗ Trợ ZaloPay

**QUAN TRỌNG**: Để có tài khoản sandbox, bạn cần liên hệ ZaloPay để họ tạo cho bạn.

1. **Các cách liên hệ**:
   - **Email**: **support@zalopay.vn** hoặc **hotro@zalopay.vn**
   - **Hotline**: **1900 545 436**
   - **Website**: **https://developers.zalopay.vn** (tìm form liên hệ)
   - **Trang Developer**: **https://docs.zalopay.vn**

2. **Nội dung email/form liên hệ**:
   ```
   Chào ZaloPay Team,
   
   Tôi đang làm project [tên project] và cần tài khoản sandbox để test tích hợp thanh toán ZaloPay.
   
   Thông tin của tôi:
   - Họ tên: [Tên của bạn]
   - Email: [Email của bạn]
   - Số điện thoại: [SĐT của bạn]
   - Mục đích: Test tích hợp thanh toán cho project [tên project]
   - Môi trường: Sandbox (chỉ để test, không phải production)
   
   Mong nhận được phản hồi sớm.
   
   Cảm ơn!
   ```

3. **Chờ phản hồi**:
   - ZaloPay sẽ xem xét và tạo tài khoản sandbox cho bạn
   - Thời gian phản hồi: Thường 1-3 ngày làm việc
   - Bạn sẽ nhận được thông tin đăng nhập qua email/SMS

### Bước 3: Đăng Nhập Vào Sandbox Portal

1. Truy cập: **https://sbmc.zalopay.vn** (Sandbox Merchant Console)
   - **Lưu ý**: Đây là portal riêng cho sandbox, khác với merchant portal thật
   - Portal thật: `https://merchant.zalopay.vn` (KHÔNG dùng cho sandbox)

2. Đăng nhập bằng thông tin đã nhận được từ ZaloPay:
   - **Email** hoặc **Số điện thoại**
   - **Mật khẩu** (từ email/SMS)

3. Nếu quên mật khẩu:
   - Click **"Quên mật khẩu"**
   - Nhập email/SĐT để nhận link đặt lại mật khẩu

---

## 2. Lấy API Credentials

### Bước 1: Truy Cập Thông Tin Tích Hợp

Sau khi đăng nhập vào **https://sbmc.zalopay.vn**:

1. Tìm menu **"Tài khoản"** (Account) hoặc **"Cài đặt"** (Settings)
2. Chọn **"Thông tin tích hợp"** (Integration Info) hoặc **"API Keys"**
3. Tại đây bạn sẽ thấy các thông tin cần thiết

### Bước 2: Lấy Thông Tin Cần Thiết

Bạn sẽ thấy các thông tin sau:

#### A. App ID
- **Mã ứng dụng** của bạn trong sandbox
- Format: Số (ví dụ: `2553`, `2554`, `2555`)
- **Vị trí**: Thường ở đầu trang "Thông tin tích hợp"
- **Lưu ý**: 
  - App ID sandbox khác với production
  - Copy chính xác, không có khoảng trắng

#### B. Key1
- **Khóa bí mật 1** - Dùng để tạo signature khi gọi API
- Format: Chuỗi ký tự dài (thường 32-64 ký tự)
- **Vị trí**: Trong phần "Thông tin tích hợp"
- **QUAN TRỌNG**: 
  - Giữ bí mật, không chia sẻ công khai
  - Không commit lên Git
  - Key1 sandbox chỉ dùng cho sandbox

#### C. Key2
- **Khóa bí mật 2** - Dùng để verify signature từ callback
- Format: Chuỗi ký tự dài (thường 32-64 ký tự)
- **Vị trí**: Trong phần "Thông tin tích hợp"
- **QUAN TRỌNG**: 
  - Giữ bí mật, không chia sẻ công khai
  - Không commit lên Git
  - Key2 sandbox chỉ dùng cho sandbox

### Bước 3: Thiết Lập Callback URL

1. Trong sandbox portal, tìm phần **"Callback URL"** hoặc **"Redirect URL"**
2. Thiết lập URL: `https://xcinema.app/zalopay/callback`
   - **Lưu ý**: URL này phải là HTTPS và có thể truy cập được
   - ZaloPay sẽ redirect về URL này sau khi thanh toán
3. Click **"Lưu"** hoặc **"Cập nhật"**

### Bước 4: Môi Trường Sandbox

**Sandbox (Test) - Dùng Cho Project Của Bạn**
- **Base URL**: `https://sb-openapi.zalopay.vn`
- **Portal**: `https://sbmc.zalopay.vn`
- ✅ **Hoàn toàn miễn phí**
- ✅ **Không tính phí giao dịch**
- ✅ **Chỉ dùng để test**
- ✅ **Không cần đăng ký merchant thật**

**Production (Thật) - Chỉ Dùng Khi Ra Mắt Thật**
- **Base URL**: `https://openapi.zalopay.vn`
- **Portal**: `https://merchant.zalopay.vn`
- ⚠️ Cần đăng ký merchant thật
- ⚠️ Cần ký hợp đồng với ZaloPay
- ⚠️ Có phí giao dịch
- ⚠️ Dùng cho giao dịch thật

**Lưu ý**: 
- Sandbox và Production có App ID, Key1, Key2 **hoàn toàn khác nhau**
- Code đã tự động chọn sandbox khi `ZALOPAY_MODE=sandbox`

---

## 3. Cấu Hình Trong Project

### Bước 1: Thêm Credentials Vào `.env`

1. Mở file `.env` trong project
2. Thêm các thông tin sau:

```env
# ZaloPay Configuration (Sandbox)
ZALOPAY_APP_ID=your_app_id_here
ZALOPAY_KEY1=your_key1_here
ZALOPAY_KEY2=your_key2_here
ZALOPAY_MODE=sandbox
ZALOPAY_RETURN_URL=https://xcinema.app/zalopay/callback
```

**Ví dụ thực tế - Bộ 1 (Mặc định)**:
```env
# ZaloPay Configuration (Sandbox) - Bộ 1
ZALOPAY_APP_ID=2554
ZALOPAY_KEY1=sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn
ZALOPAY_KEY2=trMrHtvjo6myautxDUiAcYsVtaeQ8nhf
ZALOPAY_MODE=sandbox
ZALOPAY_RETURN_URL=https://xcinema.app/zalopay/callback
```

**Ví dụ thực tế - Bộ 2 (Thay thế)**:
```env
# ZaloPay Configuration (Sandbox) - Bộ 2
ZALOPAY_APP_ID=554
ZALOPAY_KEY1=8NdU5pG5R2spGHGhyO99HN1OhD8IQJBn
ZALOPAY_KEY2=uUfsWgfLkRLzq6W2uNXTCxrfxs51auny
ZALOPAY_MODE=sandbox
ZALOPAY_RETURN_URL=https://xcinema.app/zalopay/callback
```

**Ví dụ thực tế - Bộ 3 (Thay thế)**:
```env
# ZaloPay Configuration (Sandbox) - Bộ 3
ZALOPAY_APP_ID=2553
ZALOPAY_KEY1=8NdU5pG5R2spGHGhyO99HN1OhD8IQJBn
ZALOPAY_KEY2=uUfsWgfLkRLzq6W2uNXTCxrfxs51auny
ZALOPAY_MODE=sandbox
ZALOPAY_RETURN_URL=https://xcinema.app/zalopay/callback
```

**Lưu ý**:
- Thay `your_app_id_here`, `your_key1_here`, `your_key2_here` bằng giá trị thật từ sandbox portal
- Không có khoảng trắng thừa
- Không có dấu ngoặc kép

### Bước 2: Kiểm Tra Code Đã Tích Hợp

Code trong `lib/services/payment_service.dart` đã:
- ✅ Load credentials từ `.env`
- ✅ Tạo order qua ZaloPay API (`/v2/create`)
- ✅ Tạo signature (HMAC SHA256 với Key1)
- ✅ Mở WebView với payment URL từ ZaloPay
- ✅ Xử lý callback và verify signature với Key2

### Bước 3: Chạy Ứng Dụng

```bash
flutter run
```

Khi chạy, kiểm tra console logs:
- `✅ ZaloPay credentials found in .env` - Nếu thấy dòng này, credentials đã được load
- `📝 ZaloPay App ID: [số]` - App ID đã được load
- `📝 ZaloPay Mode: sandbox` - Đang dùng sandbox

---

## 4. Test Thanh Toán

### Bước 1: Tải ZaloPay Sandbox App

Để test thanh toán trên mobile, bạn cần tải ZaloPay Sandbox App:

1. **Android**: 
   - Tải từ: **https://developers.zalopay.vn/start/**
   - Hoặc tìm "ZaloPay Sandbox" trên Google Play

2. **iOS**:
   - Tải từ: **https://developers.zalopay.vn/start/**
   - Hoặc tìm "ZaloPay Sandbox" trên App Store

### Bước 2: Đăng Ký Tài Khoản ZaloPay Sandbox

1. Mở ZaloPay Sandbox App
2. Đăng ký bằng số điện thoại
3. **Mã xác minh**: `111111` (mã test)
4. Thiết lập mật khẩu
5. **Lưu ý**: Một số điện thoại chỉ có thể liên kết với một tài khoản ZaloPay sandbox

### Bước 3: Nạp Tiền Vào Tài Khoản Sandbox

1. Trong ZaloPay Sandbox App, vào **"Nạp tiền"**
2. Sử dụng thông tin thẻ test:

   **Thẻ Visa/Master/JCB**:
   - Số thẻ: `4111111111111111`
   - Tên chủ thẻ: `NGUYEN VAN A`
   - Ngày hết hạn: `01/25`
   - Mã CVV: `123`

   **Thẻ ATM (SBI)**:
   - Xem danh sách tại: **https://developers.zalopay.vn/start/**

3. Nạp số tiền bạn muốn test (ví dụ: 500,000 VND)

### Bước 4: Test Thanh Toán Trong App

1. Mở ứng dụng của bạn
2. Chọn ghế và thanh toán
3. Chọn **"ZaloPay"** trong danh sách phương thức thanh toán
4. Click **"XÁC NHẬN THANH TOÁN"**
5. WebView sẽ mở với trang thanh toán ZaloPay
6. Đăng nhập ZaloPay (nếu chưa đăng nhập)
7. Xác nhận thanh toán
8. Kiểm tra kết quả

---

## 5. Troubleshooting

### Lỗi: "Giao dịch thất bại" (-401)

**Nguyên nhân**:
- Signature không đúng
- Format `app_trans_id` không đúng
- Thiếu hoặc sai parameters

**Giải pháp**:
1. Kiểm tra Key1 có đúng không
2. Kiểm tra format `app_trans_id`: `YYMMDD_appid_random` (max 40 chars)
3. Kiểm tra console logs để xem MAC data và signature
4. Đảm bảo `embed_data` là empty string hoặc JSON string hợp lệ

### Lỗi: "Không thể tìm thấy trang"

**Nguyên nhân**:
- Payment URL không đúng
- URL không tồn tại

**Giải pháp**:
1. Kiểm tra `order_url` từ API response
2. Đảm bảo URL bắt đầu bằng `https://`
3. Kiểm tra console logs để xem URL được tạo

### Lỗi: "App ID không hợp lệ"

**Nguyên nhân**:
- App ID sai hoặc không đúng môi trường

**Giải pháp**:
1. Kiểm tra App ID trong `.env` có đúng không
2. Đảm bảo App ID đúng cho sandbox (không dùng production App ID)
3. Kiểm tra `ZALOPAY_MODE=sandbox`

### Lỗi: "Signature không hợp lệ"

**Nguyên nhân**:
- Key1 sai
- MAC data không đúng format

**Giải pháp**:
1. Kiểm tra Key1 trong `.env` có đúng không
2. Kiểm tra MAC data format: `app_id|app_trans_id|app_user|amount|app_time|embed_data|item`
3. Đảm bảo không có khoảng trắng thừa trong Key1

### API Trả Về Lỗi -401

**Nguyên nhân**:
- Public sandbox credentials không hoạt động
- Cần credentials riêng từ tài khoản sandbox
- Credentials hiện tại đã hết hạn hoặc bị vô hiệu hóa

**Giải pháp**:

**Bước 1: Thử các bộ credentials khác**
1. Thử Bộ 2 (App ID: 554) - xem phần "Thử Credentials Khác" ở trên
2. Thử Bộ 3 (App ID: 2553) - xem phần "Thử Credentials Khác" ở trên
3. Mỗi lần thử, lưu file `.env` và chạy lại app

**Bước 2: Debug Chi Tiết**
Xem file **[ZALOPAY_DEBUG_GUIDE.md](./ZALOPAY_DEBUG_GUIDE.md)** để:
- Test API trực tiếp
- Kiểm tra lỗi cụ thể
- Xem hướng dẫn debug chi tiết

**Bước 3: Giải Pháp Thay Thế (Không Cần Đăng Ký ZaloPay)**

Nếu tất cả credentials đều không hoạt động và bạn **KHÔNG MUỐN ĐĂNG KÝ**, có thể dùng:

#### Option 1: Cổng Thanh Toán Trung Gian - Checkout.vn ⭐ (Khuyến nghị)

**Ưu điểm:**
- ✅ **KHÔNG cần đăng ký ZaloPay trực tiếp**
- ✅ Hỗ trợ nhiều cổng thanh toán (ZaloPay, VNPay, MoMo, v.v.)
- ✅ API đơn giản hơn ZaloPay
- ✅ Có sandbox để test miễn phí
- ✅ Tích hợp nhanh (1-2 giờ)

**Cách dùng:**
1. Đăng ký tại: **https://checkout.vn** (miễn phí)
2. Lấy API key từ dashboard
3. Tích hợp vào app (API REST đơn giản)
4. Chọn ZaloPay làm phương thức thanh toán

**Tài liệu:** https://help.checkout.vn/zalopay.html

#### Option 2: PayOS

**Ưu điểm:**
- ✅ Hỗ trợ ZaloPay
- ✅ API REST đơn giản
- ✅ Có sandbox

**Cách dùng:**
1. Đăng ký tại: **https://payos.vn**
2. Lấy API key
3. Tích hợp vào app

**Bước 4: Nếu Muốn Dùng ZaloPay Trực Tiếp**

1. Đăng ký tài khoản sandbox riêng (theo hướng dẫn ở trên)
2. Lấy App ID, Key1, Key2 từ sandbox portal
3. Thêm vào `.env` và test lại

**Hoặc liên hệ ZaloPay:**
- **Email**: support@zalopay.vn hoặc hotro@zalopay.vn
- **Hotline**: 1900 545 436
- Yêu cầu: "Cần tài khoản sandbox để test tích hợp, public credentials không hoạt động"

---

## 📚 Tài Liệu Tham Khảo

- **ZaloPay Developer**: https://developers.zalopay.vn
- **ZaloPay Documentation**: https://docs.zalopay.vn
- **ZaloPay Sandbox Portal**: https://sbmc.zalopay.vn
- **API Documentation**: https://docs.zalopay.vn/vi/docs/specs/order-create/
- **Debug Guide**: [ZALOPAY_DEBUG_GUIDE.md](./ZALOPAY_DEBUG_GUIDE.md) - Hướng dẫn debug chi tiết

## 🔄 Giải Pháp Thay Thế (Không Cần Đăng Ký ZaloPay)

Nếu cả 3 bộ credentials đều không hoạt động và bạn **KHÔNG MUỐN ĐĂNG KÝ ZaloPay**, hãy xem:

### ✅ Option 1: Checkout.vn (Khuyến nghị)

**Ưu điểm:**
- ✅ **KHÔNG cần đăng ký ZaloPay trực tiếp**
- ✅ Hỗ trợ ZaloPay + nhiều cổng khác (VNPay, MoMo, v.v.)
- ✅ API đơn giản, tích hợp nhanh
- ✅ Có sandbox miễn phí

**Link:** https://checkout.vn

### ✅ Option 2: PayOS

**Ưu điểm:**
- ✅ Hỗ trợ ZaloPay
- ✅ API REST đơn giản

**Link:** https://payos.vn

Xem chi tiết trong [ZALOPAY_DEBUG_GUIDE.md](./ZALOPAY_DEBUG_GUIDE.md)

---

## ⚠️ Lưu Ý Quan Trọng

1. **Sandbox vs Production**:
   - ✅ **Sandbox**: Miễn phí, không cần đăng ký merchant thật, chỉ để test
   - ⚠️ **Production**: Cần đăng ký merchant thật, có phí, dùng cho giao dịch thật
   - 🔒 **Sandbox credentials KHÔNG dùng được cho Production** và ngược lại

2. **Bảo Mật Credentials**:
   - ❌ KHÔNG commit `.env` lên Git
   - ❌ KHÔNG chia sẻ Key1, Key2 công khai
   - ✅ Thêm `.env` vào `.gitignore`
   - ✅ Chỉ dùng credentials trong `.env` file

3. **Signature**:
   - Key1: Dùng để tạo signature khi gọi API
   - Key2: Dùng để verify signature từ callback
   - Format MAC data: `app_id|app_trans_id|app_user|amount|app_time|embed_data|item`

4. **Return URL**:
   - Phải là URL hợp lệ (HTTP/HTTPS)
   - ZaloPay sẽ redirect về URL này sau khi thanh toán
   - URL phải được thiết lập trong sandbox portal

5. **Test Wallet**:
   - Cần tải **ZaloPay Sandbox App** để test thanh toán trên mobile
   - Cần nạp tiền vào tài khoản sandbox (tiền ảo, không mất phí)
   - Có thể dùng thẻ test: Visa `4111111111111111`, CVV `123`, hết hạn `01/25`

---

## ✅ Checklist

Trước khi test, đảm bảo:

- [ ] Đã liên hệ ZaloPay để tạo tài khoản sandbox
- [ ] Đã nhận được thông tin đăng nhập từ ZaloPay
- [ ] Đã đăng nhập vào https://sbmc.zalopay.vn
- [ ] Đã lấy App ID, Key1, Key2 từ sandbox portal
- [ ] Đã thêm credentials vào `.env`
- [ ] Đã kiểm tra `ZALOPAY_MODE=sandbox`
- [ ] Đã kiểm tra `ZALOPAY_RETURN_URL` hợp lệ
- [ ] Đã tải ZaloPay Sandbox App (nếu test trên mobile)
- [ ] Đã nạp tiền vào tài khoản sandbox (nếu test trên mobile)
- [ ] Đã chạy `flutter run` và test thanh toán

---

## 🎯 Tóm Tắt Quy Trình

1. **Liên hệ ZaloPay** → Email: support@zalopay.vn hoặc hotline: 1900 545 436
2. **Nhận thông tin đăng nhập** → Từ email/SMS của ZaloPay
3. **Đăng nhập** → https://sbmc.zalopay.vn
4. **Lấy credentials** → App ID, Key1, Key2 từ "Thông tin tích hợp"
5. **Thêm vào `.env`** → Cấu hình credentials
6. **Test** → Chạy app và test thanh toán

---

**Chúc bạn tích hợp thành công! 🎉**
