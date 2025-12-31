# 🔍 VNPay Signature Debug Guide

Hướng dẫn debug lỗi "Sai chữ ký" khi tích hợp VNPay.

## 📋 Các Bước Kiểm Tra

### 1. Kiểm Tra Credentials

Đảm bảo credentials trong `.env` đúng:
```env
VNPAY_TMN_CODE=MVAEXTFI
VNPAY_HASH_SECRET=RQ786UEM3P7M990ULPB9VF6LLHHSUAIK
VNPAY_BASE_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_RETURN_URL=https://xcinema.app/vnpay/callback
VNPAY_MODE=sandbox
```

### 2. Kiểm Tra Console Logs

Khi chạy thanh toán, kiểm tra console logs:
- `Hash data (raw, for signature): ...` - Query string dùng để tạo hash
- `Secure Hash: ...` - Hash được tạo ra
- `TMN Code: ...` - Mã TMN
- `Amount: ...` - Số tiền (đã nhân 100)

### 3. Các Nguyên Nhân Thường Gặp

#### A. Hash Secret Không Đúng
- ✅ Kiểm tra `VNPAY_HASH_SECRET` trong `.env`
- ✅ Đảm bảo không có khoảng trắng thừa
- ✅ Đảm bảo đúng hash secret cho sandbox (không dùng production)

#### B. TMN Code Không Đúng
- ✅ Kiểm tra `VNPAY_TMN_CODE` trong `.env`
- ✅ Đảm bảo đúng TMN code cho sandbox

#### C. Thứ Tự Parameters
- ✅ Parameters phải được sắp xếp theo alphabet
- ✅ Code đã tự động sắp xếp: `sortedKeys = params.keys.toList()..sort()`

#### D. Format Của Các Giá Trị
- ✅ `vnp_Amount`: Phải nhân 100 (ví dụ: 100000 VND = 10000000)
- ✅ `vnp_CreateDate`: Format YYYYMMDDHHmmss (ví dụ: 20250101143000)
- ✅ `vnp_Locale`: 'vn' (không phải 'vi')
- ✅ `vnp_OrderInfo`: Mô tả đơn hàng (có thể có ký tự đặc biệt)

#### E. Cách Tạo Hash
- ✅ Hash từ raw query string (không encode)
- ✅ Format: `key1=value1&key2=value2&key3=value3`
- ✅ HMAC SHA512 với hash secret
- ✅ Convert sang uppercase

### 4. Test Signature Thủ Công

Bạn có thể test signature bằng cách:

1. Lấy hash data từ console log
2. Sử dụng tool online để tạo HMAC SHA512:
   - https://www.freeformatter.com/hmac-generator.html
   - Chọn algorithm: SHA512
   - Secret key: `RQ786UEM3P7M990ULPB9VF6LLHHSUAIK`
   - Message: hash data từ log
   - So sánh kết quả với Secure Hash trong log

### 5. Kiểm Tra URL Cuối Cùng

URL thanh toán phải có format:
```
https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Amount=...&vnp_Command=pay&...&vnp_SecureHash=...
```

Đảm bảo:
- ✅ Tất cả parameters đều có giá trị
- ✅ `vnp_SecureHash` ở cuối cùng
- ✅ Tất cả values đều được URL encode (trừ khi tạo hash)

## 🔧 Cách Sửa

Nếu vẫn lỗi, thử các cách sau:

### Cách 1: Hash từ Raw Query String (Hiện tại)
```dart
final hashData = sortedKeys.map((key) => '$key=${params[key]}').join('&');
```

### Cách 2: Hash từ Encoded Query String
```dart
final hashData = sortedKeys.map((key) => '$key=${Uri.encodeComponent(params[key]!)}').join('&');
```

### Cách 3: Hash với Space = +
```dart
final hashData = sortedKeys.map((key) {
  final encoded = Uri.encodeComponent(params[key]!).replaceAll('%20', '+');
  return '$key=$encoded';
}).join('&');
```

## 📞 Liên Hệ Hỗ Trợ

Nếu vẫn không được, liên hệ VNPay:
- Hotline: 1900 55 55 77
- Email: hotrovnpay@vnpay.vn

