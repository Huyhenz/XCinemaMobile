# 💜 Hướng Dẫn Cấu Hình MoMo API (Sandbox/Test)

Hướng dẫn chi tiết để tích hợp MoMo API vào ứng dụng XCinema cho môi trường test/sandbox.

> **💡 Lưu ý**: Bạn **KHÔNG cần** trở thành đối tác chính thức để sử dụng sandbox/test environment. Bạn có thể đăng ký tài khoản developer miễn phí hoặc sử dụng mock payment để test.

## 📋 Mục Lục

1. [Đăng Ký Tài Khoản Developer (Cho Môi Trường Test/Sandbox)](#1-đăng-ký-tài-khoản-developer-cho-môi-trường-testsandbox)
2. [Lấy Thông Tin API](#2-lấy-thông-tin-api)
3. [Cấu Hình Trong Ứng Dụng](#3-cấu-hình-trong-ứng-dụng)
4. [Kiểm Tra Tích Hợp](#4-kiểm-tra-tích-hợp)
5. [Xử Lý Callback](#5-xử-lý-callback)

---

## 1. Đăng Ký Tài Khoản MoMo (Cho Môi Trường Test/Sandbox)

### ⚠️ Tình Trạng Hiện Tại

**MoMo có thể đã thay đổi quy trình đăng ký!**

Hiện tại trên trang MoMo Business, bạn chỉ thấy nút **"Tạo Trang Doanh nghiệp"** (Create Business Page) thay vì nút đăng ký trực tiếp. Điều này có nghĩa là:

- MoMo có thể yêu cầu tạo "Trang Doanh nghiệp" trước khi có thể truy cập API
- Hoặc MoMo không còn cung cấp sandbox/test environment công khai nữa
- Quy trình đăng ký có thể phức tạp hơn và yêu cầu thông tin doanh nghiệp thật

### 💡 Khuyến Nghị Cho Project Test

**Vì bạn đang làm project test, chúng tôi KHUYẾN NGHỊ MẠNH MẼ sử dụng Mock Payment:**

1. **Không cần đăng ký** - Tiết kiệm thời gian và công sức
2. **Test ngay lập tức** - Không cần chờ phê duyệt
3. **Đủ để test UI/UX** - Mock payment đã đủ để test toàn bộ flow
4. **Hoàn toàn miễn phí** - Không cần cung cấp thông tin doanh nghiệp

**Xem phần [Test Với Mock Payment](#-test-với-mock-payment-không-cần-credentials) bên dưới để bắt đầu ngay!**

---

### Nếu Vẫn Muốn Đăng Ký (Không Khuyến Nghị Cho Project Test)

Nếu bạn vẫn muốn thử đăng ký để lấy sandbox credentials:

#### Cách 1: Tạo Trang Doanh nghiệp

1. Truy cập: **https://business.momo.vn/trang-doanh-nghiep**
2. Click nút **"Tạo Trang Doanh nghiệp"** (Create Business Page)
3. Điền thông tin doanh nghiệp
4. Sau khi tạo trang, có thể sẽ có option để truy cập API/Sandbox credentials

#### Cách 2: Liên Hệ Trực Tiếp

1. Liên hệ MoMo qua email hoặc hotline
2. Hỏi về việc đăng ký sandbox/test environment
3. Cung cấp thông tin về project của bạn

#### Cách 3: Đăng Nhập (Nếu Đã Có Tài Khoản)

1. Nếu bạn đã có tài khoản MoMo Business trước đó
2. Đăng nhập tại: **https://business.momo.vn/**
3. Tìm mục **"Tích hợp website"** hoặc **"API Integration"**
4. Lấy sandbox credentials nếu có

### ⏱️ Thời Gian (Nếu Đăng Ký)

- Tạo Trang Doanh nghiệp: **10-15 phút**
- Chờ phê duyệt: **Vài ngày đến vài tuần** (nếu cần)
- Lấy credentials: **Sau khi được phê duyệt** (nếu có sandbox)

### 💡 Nếu Không Muốn Đăng Ký (Khuyến Nghị Cho Project Test)

**Nếu bạn chỉ đang làm project và muốn test UI/UX:**

Ứng dụng đã được cấu hình sẵn để sử dụng **mock payment** (thanh toán mô phỏng) khi không có credentials. Bạn có thể:

1. **Bỏ qua việc đăng ký** - Không cần thêm gì vào `.env`
2. **Test ngay lập tức** - Chạy app và test flow thanh toán
3. **Test toàn bộ flow**:
   - Chọn MoMo trong danh sách phương thức thanh toán
   - Mở WebView với giao diện MoMo mock
   - Test success/cancel flow
   - Xem màn hình thành công/thất bại

**Mock payment hoàn toàn an toàn, không có giao dịch thật, và phù hợp cho việc test project!**

> **💡 Tip**: Nếu sau này cần test với API thật, bạn có thể đăng ký lúc đó. Hiện tại, mock payment đã đủ để test UI/UX và flow thanh toán.

---

## 2. Lấy Thông Tin API (Sandbox)

Sau khi tạo project trong sandbox, bạn sẽ nhận được các thông tin sau:

### Thông Tin Cần Thiết:

1. **Partner Code** (`MOMO_PARTNER_CODE`)
   - Mã đối tác của bạn
   - Format: Chuỗi ký tự (ví dụ: `MOMOXXXX20240101`)

2. **Access Key** (`MOMO_ACCESS_KEY`)
   - Khóa truy cập API
   - Dùng để tạo signature

3. **Secret Key** (`MOMO_SECRET_KEY`)
   - Khóa bí mật để tạo signature
   - **QUAN TRỌNG**: Giữ bí mật, không chia sẻ công khai

4. **API Endpoints**:
   - **Sandbox (Test)**: `https://test-payment.momo.vn`
   - **Production**: `https://payment.momo.vn`

### Tài Liệu API

- **Tài liệu chính thức**: https://developers.momo.vn/v3/vi/docs/payment/onboarding/overall/
- **Hướng dẫn tích hợp**: https://developers.momo.vn/v3/vi/docs/payment/onboarding/overall/

---

## 3. Cấu Hình Trong Ứng Dụng

### Bước 1: Thêm Credentials vào file `.env` (Tùy Chọn)

**Nếu bạn đã có sandbox credentials từ MoMo Developer:**

Mở file `.env` trong thư mục gốc của project và thêm các dòng sau:

```env
# MoMo Configuration (Sandbox/Test)
MOMO_PARTNER_CODE=your_sandbox_partner_code
MOMO_ACCESS_KEY=your_sandbox_access_key
MOMO_SECRET_KEY=your_sandbox_secret_key
MOMO_MODE=sandbox
```

**Nếu bạn CHƯA có credentials (chỉ muốn test UI):**

Bạn có thể **bỏ qua bước này**. Ứng dụng sẽ tự động sử dụng mock payment để bạn có thể test toàn bộ flow thanh toán mà không cần credentials thật.

**Lưu ý:**
- Thay `your_sandbox_partner_code`, v.v. bằng các giá trị từ MoMo Developer Dashboard
- Đặt `MOMO_MODE=sandbox` cho môi trường test
- Nếu không có credentials, ứng dụng vẫn hoạt động với mock payment

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
✅ MoMo credentials found in .env
📝 MoMo Partner Code: MOMOXXXX20...
📝 MoMo Mode: sandbox
```

Nếu không thấy, sẽ có cảnh báo:

```
⚠️ MoMo credentials not found in .env (MoMo payment will use mock)
💡 To enable real MoMo payment, add MOMO_PARTNER_CODE, MOMO_ACCESS_KEY, MOMO_SECRET_KEY to .env file
```

### Test Thanh Toán

1. Mở ứng dụng và chọn một bộ phim
2. Chọn ghế và chuyển đến màn hình thanh toán
3. Chọn **MoMo** làm phương thức thanh toán
4. Nếu cấu hình đúng:
   - Ứng dụng sẽ gọi API MoMo để tạo đơn hàng
   - Mở WebView với trang thanh toán thật từ MoMo
   - Sau khi thanh toán thành công, sẽ quay về màn hình thành công

### Nếu Chưa Có Credentials (Mock Payment)

- Ứng dụng sẽ tự động sử dụng **mock payment** (thanh toán mô phỏng)
- Bạn vẫn có thể test **toàn bộ flow thanh toán**:
  - Chọn phương thức MoMo
  - Mở WebView với giao diện MoMo
  - Test success/cancel flow
  - Xem màn hình thành công/thất bại
- **Không cần đăng ký hay credentials** để test UI/UX
- Mock payment hoàn toàn an toàn, không có giao dịch thật

---

## 5. Xử Lý Callback

### Return URLs

MoMo sẽ redirect về các URL sau sau khi thanh toán:

- **Success URL**: `https://xcinema.app/momo/success?transactionId=...&orderId=...`
- **Cancel URL**: `https://xcinema.app/momo/cancel`

### WebView Navigation Detection

Ứng dụng tự động phát hiện khi người dùng:
- Thanh toán thành công → Đóng WebView và hiển thị màn hình thành công
- Hủy thanh toán → Đóng WebView và hiển thị màn hình thất bại

### Verify Payment (Backend)

**QUAN TRỌNG**: Trong môi trường production, bạn cần:

1. **Tạo backend endpoint** để nhận webhook từ MoMo:
   ```
   POST https://your-backend.com/momo/webhook
   ```

2. **Verify payment signature** từ MoMo để đảm bảo giao dịch hợp lệ
   - MoMo sử dụng HMAC SHA256 để tạo signature
   - Bạn cần verify signature trước khi xử lý payment

3. **Cập nhật trạng thái đơn hàng** trong database

4. **Gửi email xác nhận** cho khách hàng

### Tạo Signature (Backend)

MoMo yêu cầu tạo signature bằng HMAC SHA256. Ví dụ:

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String createMoMoSignature(Map<String, dynamic> params, String secretKey) {
  // Sắp xếp các tham số theo thứ tự alphabet
  final sortedKeys = params.keys.toList()..sort();
  final queryString = sortedKeys.map((key) => '$key=${params[key]}').join('&');
  
  // Tạo HMAC SHA256
  final key = utf8.encode(secretKey);
  final bytes = utf8.encode(queryString);
  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(bytes);
  
  return digest.toString();
}
```

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
   - Luôn verify signature từ MoMo
   - Kiểm tra `resultCode` trong response

5. **Tạo signature đúng cách**
   - Sắp xếp parameters theo thứ tự alphabet
   - Sử dụng HMAC SHA256
   - Không bao gồm signature trong query string khi tạo signature

---

## 📚 Tài Liệu Tham Khảo

- **Trang đăng ký Doanh nghiệp**: https://business.momo.vn/trang-doanh-nghiep
- **Trang quản trị (Sau khi đăng ký)**: https://business.momo.vn/
- **Tài liệu API chính thức**: https://developers.momo.vn/v3/vi/docs/payment/onboarding/overall/
- **Hướng dẫn tích hợp**: https://developers.momo.vn/v3/vi/docs/payment/onboarding/overall/
- **Liên hệ hỗ trợ**: Qua email hoặc hotline từ MoMo

> **💡 Lưu ý**: Nếu bạn chỉ đang làm project test, **không cần đăng ký**. Sử dụng mock payment đã đủ để test UI/UX và flow thanh toán!

---

## ❓ Troubleshooting

### Lỗi: "Không thể kết nối với MoMo"

**Nguyên nhân có thể:**
- Credentials không đúng
- Network connection issue
- MoMo API đang bảo trì

**Giải pháp:**
1. Kiểm tra lại credentials trong `.env`
2. Kiểm tra kết nối internet
3. Thử lại sau vài phút

### Lỗi: "Không thể tạo đơn hàng MoMo"

**Nguyên nhân có thể:**
- Partner Code, Access Key hoặc Secret Key không đúng
- Signature không đúng (nếu đã implement)
- Thiếu thông tin bắt buộc trong request

**Giải pháp:**
1. Kiểm tra lại `MOMO_PARTNER_CODE`, `MOMO_ACCESS_KEY`, `MOMO_SECRET_KEY`
2. Xem log chi tiết trong console để biết lỗi cụ thể
3. Đảm bảo đang dùng đúng environment (sandbox/production)

### WebView không load được trang thanh toán

**Nguyên nhân có thể:**
- Payment URL không hợp lệ
- MoMo redirect về URL không đúng

**Giải pháp:**
1. Kiểm tra log để xem payment URL được tạo ra
2. Thử mở URL trong browser để kiểm tra
3. Liên hệ MoMo support nếu vấn đề vẫn tiếp tục

### Lỗi Signature Verification

**Nguyên nhân có thể:**
- Secret Key không đúng
- Cách tạo signature không đúng
- Parameters không được sắp xếp đúng thứ tự

**Giải pháp:**
1. Kiểm tra lại Secret Key
2. Đảm bảo parameters được sắp xếp theo thứ tự alphabet
3. Sử dụng đúng thuật toán HMAC SHA256
4. Tham khảo tài liệu MoMo về cách tạo signature

---

## 🧪 Test Với Mock Payment (KHUYẾN NGHỊ - Không Cần Credentials)

**Đây là cách đơn giản nhất và được khuyến nghị cho project test!**

Vì MoMo có thể đã thay đổi quy trình đăng ký và không còn dễ dàng để lấy sandbox credentials, bạn nên sử dụng Mock Payment:

### Bước 1: Không Cần Làm Gì Cả!

- **Không cần thêm gì vào `.env`**
- **Không cần đăng ký tài khoản**
- Ứng dụng sẽ tự động dùng mock payment

### Bước 2: Chạy Ứng Dụng

```bash
flutter run
```

### Bước 3: Test Flow Thanh Toán

1. Mở app và chọn một bộ phim
2. Chọn ghế và chuyển đến màn hình thanh toán
3. Chọn **MoMo** trong danh sách phương thức thanh toán
4. Click **"XÁC NHẬN THANH TOÁN"**
5. WebView sẽ hiển thị giao diện MoMo mock (màu tím #A50064)
6. Test các flow:
   - Click **"Xác nhận thanh toán"** → Test success flow → Xem màn hình thành công
   - Click **"Hủy"** → Test cancel flow → Xem màn hình thất bại

### ✅ Lợi Ích Của Mock Payment

- ✅ **Hoàn toàn miễn phí** - Không cần đăng ký
- ✅ **Test ngay lập tức** - Không cần chờ phê duyệt
- ✅ **An toàn 100%** - Không có giao dịch thật
- ✅ **Đủ để test UI/UX** - Test được toàn bộ flow thanh toán
- ✅ **Phù hợp cho project** - Lý tưởng cho việc demo/presentation

**Mock payment hoàn toàn đủ để test project của bạn!**

---

## ✅ Checklist

### Cho Môi Trường Test/Sandbox:

- [ ] (Tùy chọn) Đăng ký tài khoản MoMo Developer tại https://developers.momo.vn/
- [ ] (Tùy chọn) Tạo project và lấy sandbox credentials
- [ ] (Tùy chọn) Thêm credentials vào `.env` nếu muốn test với API thật
- [ ] Test thanh toán với mock payment (không cần credentials)
- [ ] Hoặc test với sandbox credentials nếu đã có
- [ ] Kiểm tra UI/UX flow thanh toán

### Trước khi deploy production, đảm bảo:

- [ ] Đã đăng ký và được phê duyệt bởi MoMo Business
- [ ] Đã thêm production credentials vào `.env`
- [ ] Đã test thanh toán thành công trong sandbox mode
- [ ] Đã tạo backend endpoint để verify payment
- [ ] Đã implement signature verification đúng cách
- [ ] Đã cấu hình return URLs đúng
- [ ] Đã thêm `.env` vào `.gitignore`
- [ ] Đã chuyển sang `MOMO_MODE=production`
- [ ] Đã test lại trong production mode
- [ ] Đã setup webhook để nhận payment notifications

---

## 💡 Lưu Ý Quan Trọng

1. **Signature Verification**: MoMo yêu cầu verify signature cho mọi request. Đảm bảo bạn implement đúng cách.

2. **IPN (Instant Payment Notification)**: MoMo sẽ gửi webhook đến `ipnUrl` sau khi payment hoàn tất. Bạn cần xử lý webhook này để cập nhật trạng thái đơn hàng.

3. **Test Cards**: Trong sandbox mode, MoMo cung cấp test cards để test thanh toán. Tham khảo tài liệu MoMo để biết thêm chi tiết.

4. **Rate Limiting**: MoMo có giới hạn số lượng request. Đảm bảo bạn không gọi API quá nhiều lần.

---

**Chúc bạn tích hợp thành công! 🎉**

