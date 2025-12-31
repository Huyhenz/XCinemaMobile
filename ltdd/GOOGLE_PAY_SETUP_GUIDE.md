# Hướng Dẫn Cấu Hình Google Pay - Đã Hoàn Thành ✅

## 📋 Tóm Tắt

Code đã được cấu hình đầy đủ để tích hợp Google Pay. Khi user chọn Google Pay payment, app sẽ:
1. ✅ Kiểm tra Google Pay có khả dụng trên thiết bị
2. ✅ Hiển thị Google Pay sheet
3. ✅ Xử lý payment token
4. ✅ Trả về kết quả thanh toán

## 🔧 Các File Đã Được Cấu Hình

### 1. `pubspec.yaml`
- ✅ Đã thêm package `pay: ^2.0.0` để tích hợp Google Pay

### 2. `lib/services/payment_service.dart`
- ✅ Đã tích hợp Google Pay API thật
- ✅ Đã có logic kiểm tra Google Pay availability
- ✅ Đã có logic hiển thị Google Pay sheet
- ✅ Đã có logic xử lý payment result
- ✅ Đã chuyển đổi VND sang USD (Google Pay hỗ trợ USD)

### 3. `android/app/src/main/AndroidManifest.xml`
- ✅ Đã thêm queries cho Google Pay

### 4. `lib/screens/payment_screen.dart`
- ✅ Đã có UI cho Google Pay
- ✅ Đã truyền `context` vào `PaymentService.processPayment()`

## ⚙️ Cấu Hình Cần Thiết

### Bước 1: Cài Đặt Dependencies

Chạy lệnh sau để cài đặt package mới:

```bash
flutter pub get
```

### Bước 2: Cấu Hình Payment Gateway (Production)

**LƯU Ý QUAN TRỌNG**: Google Pay yêu cầu một Payment Gateway (như Stripe, Square, Adyen, etc.) để xử lý thanh toán thật.

Hiện tại code đang sử dụng **TEST mode** với cấu hình mẫu. Để sử dụng trong production:

1. **Chọn Payment Gateway**:
   - Stripe (khuyến nghị)
   - Square
   - Adyen
   - Hoặc gateway khác hỗ trợ Google Pay

2. **Cập nhật Payment Configuration** trong `lib/services/payment_service.dart`:
   ```dart
   final paymentConfiguration = PaymentConfiguration.fromJsonString('''
   {
     "provider": "google_pay",
     "data": {
       "environment": "PRODUCTION", // Thay đổi từ TEST
       "apiVersion": 2,
       "apiVersionMinor": 0,
       "allowedPaymentMethods": [
         {
           "type": "CARD",
           "parameters": {
             "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
             "allowedCardNetworks": ["AMEX", "DISCOVER", "JCB", "MASTERCARD", "VISA"]
           },
           "tokenizationSpecification": {
             "type": "PAYMENT_GATEWAY",
             "parameters": {
               "gateway": "stripe", // Thay bằng gateway của bạn
               "gatewayMerchantId": "YOUR_GATEWAY_MERCHANT_ID" // Thay bằng Merchant ID của bạn
             }
           }
         }
       ],
       "merchantInfo": {
         "merchantId": "YOUR_MERCHANT_ID", // Thay bằng Merchant ID của bạn
         "merchantName": "XCinema"
       },
       "transactionInfo": {
         "totalPriceStatus": "FINAL",
         "totalPriceLabel": "Total",
         "totalPrice": "${payAmount.toStringAsFixed(2)}",
         "currencyCode": "$payCurrency"
       }
     }
   }
   ''');
   ```

3. **Xử Lý Payment Token trên Backend**:
   - Khi Google Pay trả về payment token, bạn cần gửi token này đến backend
   - Backend sẽ xử lý thanh toán thông qua Payment Gateway
   - Backend trả về transaction ID thật

### Bước 3: Cập Nhật Backend Processing

Trong `processGooglePayPayment()`, sau khi nhận được `paymentResult`, bạn cần:

```dart
// Gửi payment token đến backend
final response = await http.post(
  Uri.parse('YOUR_BACKEND_URL/process-google-pay'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'paymentData': paymentResult.toString(),
    'amount': payAmount,
    'currency': payCurrency,
  }),
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  final transactionId = data['transactionId'];
  // Sử dụng transactionId thật từ backend
}
```

## 🚀 Cách Test

### Test Mode (Hiện Tại)

1. **Chạy App**:
   ```bash
   flutter run
   ```

2. **Test Payment Flow**:
   - Chọn một phim và showtime
   - Chọn ghế ngồi
   - Nhấn "Thanh Toán"
   - Chọn phương thức "Google Pay"
   - Nhấn "Xác Nhận Thanh Toán"

3. **Google Pay Sheet**:
   - Google Pay sheet sẽ hiển thị
   - Bạn có thể test với thẻ test (nếu có)
   - Hoặc cancel để test flow hủy

### Production Mode

Sau khi cấu hình Payment Gateway:
- Google Pay sẽ kết nối với Payment Gateway thật
- Thanh toán sẽ được xử lý thật
- Transaction ID sẽ là ID thật từ Payment Gateway

## 📝 Log Messages

Khi test, bạn sẽ thấy các log messages sau:

```
💳 Processing Google Pay payment: 150000.0 VND
   ⚠️ Converted VND to USD: 150000.0 VND = 6.25 USD
✅ Google Pay is available
✅ Google Pay payment completed
   Payment data: {...}
✅ Google Pay payment successful: GOOGLEPAY_1234567890
```

## ⚠️ Lưu Ý

1. **Google Pay chỉ hoạt động trên Android và iOS**:
   - Android: Cần Google Play Services
   - iOS: Cần Apple Pay (package `pay` hỗ trợ cả hai)

2. **Payment Gateway là bắt buộc**:
   - Google Pay không xử lý thanh toán trực tiếp
   - Cần một Payment Gateway để xử lý payment token

3. **Currency Conversion**:
   - Google Pay thường hỗ trợ USD, EUR, GBP, etc.
   - VND sẽ được chuyển đổi sang USD (tỷ giá 1 USD = 24,000 VND)
   - Có thể điều chỉnh tỷ giá trong code

4. **Test vs Production**:
   - Test mode: Không cần Payment Gateway, chỉ test UI flow
   - Production mode: Cần Payment Gateway thật để xử lý thanh toán

## 🔗 Tài Liệu Tham Khảo

- [Google Pay API Documentation](https://developers.google.com/pay/api)
- [Flutter Pay Package](https://pub.dev/packages/pay)
- [Stripe Google Pay Integration](https://stripe.com/docs/google-pay)
- [Square Google Pay Integration](https://developer.squareup.com/docs/payment-form/overview)

## ✅ Checklist

- [x] Thêm package `pay` vào pubspec.yaml
- [x] Cập nhật payment_service.dart với Google Pay API
- [x] Thêm context parameter vào processGooglePayPayment
- [x] Cấu hình AndroidManifest cho Google Pay
- [ ] Cấu hình Payment Gateway (cần thiết cho production)
- [ ] Tích hợp backend để xử lý payment token
- [ ] Test trên thiết bị Android thật
- [ ] Test trên thiết bị iOS (nếu cần)

