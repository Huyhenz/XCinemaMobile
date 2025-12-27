# Hướng Dẫn Test Thanh Toán

## Tổng Quan

Ứng dụng hỗ trợ 3 phương thức thanh toán:
1. **PayPal** - Thanh toán quốc tế
2. **Google Pay** - Thanh toán qua Google
3. **ZaloPay** - Thanh toán qua ZaloPay (Việt Nam)

## Cấu Hình

### 1. PayPal

**Hiện tại**: Đang sử dụng chế độ **Mock/Simulate** (mô phỏng)

**Để tích hợp thực tế**:
1. Đăng ký tài khoản PayPal Developer tại: https://developer.paypal.com
2. Tạo ứng dụng và lấy `Client ID` và `Secret`
3. Cập nhật trong `lib/services/payment_service.dart`:
   ```dart
   static const String _paypalClientId = 'YOUR_PAYPAL_CLIENT_ID';
   static const String _paypalSecret = 'YOUR_PAYPAL_SECRET';
   ```
4. Tích hợp PayPal SDK hoặc sử dụng PayPal REST API

**Test với Mock**:
- Tỷ lệ thành công: ~90% (mô phỏng)
- Transaction ID format: `PAYPAL_[timestamp]`

### 2. Google Pay

**Hiện tại**: Đang sử dụng chế độ **Mock/Simulate** (mô phỏng)

**Để tích hợp thực tế**:
1. Đăng ký Google Pay API tại: https://pay.google.com/business/console
2. Cấu hình Merchant ID và Payment Gateway
3. Tích hợp Google Pay SDK cho Flutter
4. Cập nhật code trong `payment_service.dart`

**Test với Mock**:
- Tỷ lệ thành công: ~90% (mô phỏng)
- Transaction ID format: `GOOGLEPAY_[timestamp]`

### 3. ZaloPay

**Hiện tại**: Đang sử dụng chế độ **Mock/Simulate** (mô phỏng)

**Để tích hợp thực tế**:
1. Đăng ký tài khoản ZaloPay Developer tại: https://developers.zalopay.vn
2. Tạo ứng dụng và lấy `App ID`, `Key1`, `Key2`
3. Cập nhật trong `lib/services/payment_service.dart`:
   ```dart
   static const String _zaloPayAppId = 'YOUR_ZALOPAY_APP_ID';
   static const String _zaloPayKey1 = 'YOUR_ZALOPAY_KEY1';
   static const String _zaloPayKey2 = 'YOUR_ZALOPAY_KEY2';
   ```
4. Tích hợp ZaloPay SDK (cần native code)

**Test với Mock**:
- Tỷ lệ thành công: ~90% (mô phỏng)
- Transaction ID format: `ZALOPAY_[timestamp]`

## Cách Test

### Bước 1: Chạy Ứng Dụng

```bash
flutter run
```

### Bước 2: Test Flow Thanh Toán

1. **Đăng nhập** vào ứng dụng
2. **Chọn rạp** và **phim**
3. **Chọn suất chiếu**
4. **Chọn ghế** và nhấn "Tiếp tục"
5. **Chọn phương thức thanh toán**:
   - PayPal
   - Google Pay
   - ZaloPay
6. **Nhấn "XÁC NHẬN THANH TOÁN"**

### Bước 3: Kiểm Tra Kết Quả

**Thành công**:
- Hiển thị dialog "Thanh Toán Thành Công!"
- Booking được tạo trong database
- Payment record được lưu với:
  - `status: 'success'`
  - `transactionId: '[METHOD]_[timestamp]'`
  - `paymentMethod: 'paypal' | 'googlepay' | 'zalopay'`
- Notification được gửi
- Ghế được đánh dấu là đã đặt

**Thất bại**:
- Hiển thị SnackBar với thông báo lỗi
- Temp booking được giữ lại (có thể thử lại)
- Không tạo booking

### Bước 4: Kiểm Tra Database

**Firebase Realtime Database**:
- `payments/`: Kiểm tra payment records
- `bookings/`: Kiểm tra booking records
- `showtimes/[showtimeId]/availableSeats`: Kiểm tra ghế đã được cập nhật

## Test Cases

### Test Case 1: PayPal Payment Success
1. Chọn PayPal
2. Nhấn thanh toán
3. **Expected**: Thành công với transaction ID `PAYPAL_*`

### Test Case 2: Google Pay Payment Success
1. Chọn Google Pay
2. Nhấn thanh toán
3. **Expected**: Thành công với transaction ID `GOOGLEPAY_*`

### Test Case 3: ZaloPay Payment Success
1. Chọn ZaloPay
2. Nhấn thanh toán
3. **Expected**: Thành công với transaction ID `ZALOPAY_*`

### Test Case 4: Payment Failure
1. Chọn bất kỳ phương thức nào
2. Nhấn thanh toán
3. Nếu mock trả về failure (10% chance)
4. **Expected**: Hiển thị thông báo lỗi, có thể thử lại

### Test Case 5: Cancel Payment
1. Chọn phương thức thanh toán
2. Nhấn nút "Hủy đặt vé" hoặc back
3. **Expected**: Temp booking được xóa, ghế được trả lại

## Lưu Ý

1. **Mock Mode**: Hiện tại tất cả payment đều ở chế độ mock/simulate
2. **Success Rate**: ~90% success rate để test cả success và failure cases
3. **Transaction ID**: Được generate tự động với format `[METHOD]_[timestamp]`
4. **Real Integration**: Để tích hợp thực tế, cần:
   - Backend server để xử lý payment
   - API keys từ các nhà cung cấp
   - Test với sandbox/test mode trước

## Troubleshooting

### Lỗi: "Payment service not found"
- **Nguyên nhân**: Package chưa được cài đặt
- **Giải pháp**: Chạy `flutter pub get`

### Lỗi: "Payment failed"
- **Nguyên nhân**: Mock payment có 10% tỷ lệ thất bại (để test)
- **Giải pháp**: Thử lại, hoặc kiểm tra code trong `payment_service.dart`

### Payment không lưu vào database
- **Nguyên nhân**: Lỗi kết nối Firebase hoặc lỗi trong `savePayment`
- **Giải pháp**: Kiểm tra Firebase connection và logs

## Next Steps (Tích Hợp Thực Tế)

1. **Tạo Backend Server**:
   - Xử lý payment requests
   - Verify payment với các gateway
   - Webhook để nhận payment callbacks

2. **Tích Hợp PayPal**:
   - Sử dụng PayPal REST API hoặc SDK
   - Implement OAuth flow
   - Handle payment callbacks

3. **Tích Hợp Google Pay**:
   - Setup Google Pay API
   - Implement payment sheet
   - Process payment tokens

4. **Tích Hợp ZaloPay**:
   - Download ZaloPay SDK
   - Implement native code (Android/iOS)
   - Use MethodChannel để giao tiếp với Flutter

## Tài Liệu Tham Khảo

- PayPal Developer: https://developer.paypal.com/docs
- Google Pay API: https://developers.google.com/pay/api
- ZaloPay Developer: https://developers.zalopay.vn

