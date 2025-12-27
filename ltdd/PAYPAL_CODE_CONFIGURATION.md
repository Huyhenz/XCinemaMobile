# Hướng Dẫn Cấu Hình Code PayPal - Đã Hoàn Thành ✅

## 📋 Tóm Tắt

Code đã được cấu hình đầy đủ để tích hợp PayPal thật. Khi user chọn PayPal payment, app sẽ:
1. ✅ Lấy Access Token từ PayPal API
2. ✅ Tạo Order trên PayPal
3. ✅ Mở PayPal Checkout trong WebView
4. ✅ Xử lý khi user approve/cancel
5. ✅ Capture payment và trả về kết quả

## 🔧 Các File Đã Được Cấu Hình

### 1. `lib/services/payment_service.dart`
- ✅ Đã tích hợp PayPal REST API
- ✅ Đã có logic get access token
- ✅ Đã có logic create order
- ✅ Đã có logic capture payment
- ✅ Đã có WebView để hiển thị PayPal checkout
- ✅ Đã có logic detect approval/cancel

### 2. `lib/screens/payment_screen.dart`
- ✅ Đã truyền `context` vào `PaymentService.processPayment()`
- ✅ Đã xử lý kết quả payment

### 3. `lib/main.dart`
- ✅ Đã load file `.env` khi app khởi động

### 4. `.env`
- ✅ Đã có PayPal credentials (Client ID và Secret)

## 🚀 Cách Test

### Bước 1: Chạy App
```bash
flutter run
```

### Bước 2: Test Payment Flow
1. Chọn một phim và showtime
2. Chọn ghế ngồi
3. Nhấn "Thanh Toán"
4. Chọn phương thức "PayPal"
5. Nhấn "Xác Nhận Thanh Toán"

### Bước 3: PayPal Checkout
- WebView sẽ mở với trang PayPal login
- Đăng nhập bằng **Sandbox test account** (từ PayPal Developer Dashboard)
- Approve payment
- App sẽ tự động capture payment và đóng WebView

## 📝 Log Messages

Khi test, bạn sẽ thấy các log messages sau:

```
💳 Processing PayPal payment: 150000.0 VND
✅ PayPal order created: 5O190127TN364715T
🌐 PayPal WebView navigation: https://www.sandbox.paypal.com/checkoutnow?token=...
✅ PayPal approval detected, capturing payment...
✅ PayPal payment captured: 8X12345678901234
✅ PayPal payment successful: 8X12345678901234
```

## ⚠️ Lưu Ý Quan Trọng

### 1. Sandbox Test Account
- Bạn cần tạo **Sandbox test account** trong PayPal Developer Dashboard
- Sử dụng test account này để login khi test payment
- Không sử dụng tài khoản PayPal thật

### 2. Return URL
- Code hiện tại sử dụng `https://paypal.com/return` và `https://paypal.com/cancel`
- Đây là placeholder URLs, PayPal sẽ redirect về đây sau khi approve
- WebView sẽ detect redirect và capture payment tự động

### 3. Error Handling
- Nếu không có credentials trong `.env`, code sẽ fallback về mock payment
- Nếu PayPal API lỗi, sẽ hiển thị error message cho user

## 🔍 Troubleshooting

### Lỗi: "PayPal credentials not found"
- Kiểm tra file `.env` có ở root project không
- Kiểm tra tên biến: `PAYPAL_CLIENT_ID`, `PAYPAL_SECRET`
- Chạy `flutter clean` và `flutter pub get`

### Lỗi: "Failed to get PayPal access token"
- Kiểm tra credentials có đúng không
- Kiểm tra internet connection
- Kiểm tra PayPal API có đang hoạt động không

### WebView không mở
- Kiểm tra `webview_flutter` package đã được cài đặt
- Kiểm tra platform (Android/iOS) có hỗ trợ WebView không

### Payment không capture được
- Kiểm tra log để xem có error gì không
- Đảm bảo order đã được approve trước khi capture
- Kiểm tra access token còn valid không

## ✅ Checklist

- [x] File `.env` đã có credentials
- [x] `main.dart` đã load `.env`
- [x] `payment_service.dart` đã tích hợp PayPal API
- [x] `payment_screen.dart` đã truyền context
- [x] WebView đã được cấu hình
- [x] Logic detect approval/cancel đã hoàn chỉnh
- [x] Error handling đã có

## 🎉 Kết Luận

Code đã sẵn sàng để test PayPal payment! Chỉ cần:
1. Chạy app
2. Test payment flow
3. Sử dụng Sandbox test account để login

Nếu có lỗi, kiểm tra log messages để debug.

