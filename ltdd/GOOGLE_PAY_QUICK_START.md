# Google Pay Quick Start - Hướng Dẫn Nhanh

## ✅ Đã Hoàn Thành

Google Pay đã được tích hợp vào ứng dụng! Bạn có thể sử dụng ngay bây giờ.

## 🚀 Cách Sử Dụng

1. **Chạy app**:
   ```bash
   flutter run
   ```

2. **Test Google Pay**:
   - Chọn phim và showtime
   - Chọn ghế ngồi
   - Nhấn "Thanh Toán"
   - Chọn "Google Pay"
   - Nhấn "Xác Nhận Thanh Toán"
   - Google Pay sheet sẽ hiển thị

## ⚙️ Cấu Hình Production

### Bước 1: Chọn Payment Gateway

Google Pay yêu cầu một Payment Gateway. Khuyến nghị:
- **Stripe** (phổ biến nhất)
- Square
- Adyen
- Braintree

### Bước 2: Đăng Ký Google Pay Merchant

1. Truy cập: https://pay.google.com/business/console
2. Đăng ký tài khoản merchant
3. Lấy Merchant ID

### Bước 3: Cấu Hình Payment Gateway

1. Đăng ký tài khoản với Payment Gateway (ví dụ: Stripe)
2. Lấy Gateway Merchant ID
3. Cấu hình Google Pay trong Payment Gateway dashboard

### Bước 4: Cập Nhật Code

Trong `lib/services/payment_service.dart`, tìm dòng:

```dart
final paymentConfiguration = PaymentConfiguration.fromJsonString('''
{
  "provider": "google_pay",
  "data": {
    "environment": "TEST", // Đổi thành "PRODUCTION"
    ...
    "tokenizationSpecification": {
      "type": "PAYMENT_GATEWAY",
      "parameters": {
        "gateway": "stripe", // Thay bằng gateway của bạn
        "gatewayMerchantId": "YOUR_GATEWAY_MERCHANT_ID" // Thay bằng ID thật
      }
    },
    "merchantInfo": {
      "merchantId": "YOUR_MERCHANT_ID", // Thay bằng Merchant ID thật
      "merchantName": "XCinema"
    },
    ...
  }
}
''');
```

### Bước 5: Tích Hợp Backend

Sau khi nhận được `paymentResult` từ Google Pay, bạn cần:

1. Gửi payment token đến backend
2. Backend xử lý thanh toán qua Payment Gateway
3. Backend trả về transaction ID thật

Ví dụ code:

```dart
if (paymentResult != null) {
  // Gửi đến backend
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
    // Sử dụng transactionId thật
  }
}
```

## 📝 Lưu Ý

1. **Test Mode**: Hiện tại đang dùng TEST mode, chỉ test UI flow
2. **Production Mode**: Cần Payment Gateway thật để xử lý thanh toán
3. **Currency**: VND sẽ được chuyển đổi sang USD (1 USD = 24,000 VND)
4. **Android Only**: Google Pay chỉ hoạt động trên Android (iOS dùng Apple Pay)

## 🔗 Tài Liệu

- [Google Pay API](https://developers.google.com/pay/api)
- [Flutter Pay Package](https://pub.dev/packages/pay)
- [Stripe Google Pay](https://stripe.com/docs/google-pay)

