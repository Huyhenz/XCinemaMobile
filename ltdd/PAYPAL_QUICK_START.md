# PayPal Quick Start Guide - Hướng Dẫn Nhanh

## 📋 Checklist Nhanh

### ✅ Bước 1: Đăng Ký PayPal Developer (5 phút)
1. Truy cập: https://developer.paypal.com
2. Đăng nhập hoặc tạo tài khoản mới
3. Vào **"My Apps & Credentials"**
4. Nhấn **"Create App"**
5. Đặt tên app: `XCinema Mobile`
6. Chọn **"Sandbox"** mode
7. **Copy Client ID và Secret** → Lưu lại!

### ✅ Bước 2: Cài Đặt Packages (2 phút)
```bash
# Thêm vào pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0
  # Chọn 1 trong các package sau:
  paypal_payment: ^1.0.6
  # HOẶC
  # webview_flutter: ^4.4.2  # Nếu dùng WebView

# Chạy
flutter pub get
```

### ✅ Bước 3: Tạo File .env (1 phút)
Tạo file `.env` ở **root project** (cùng cấp với `pubspec.yaml`):

```env
PAYPAL_CLIENT_ID=AeA1QIZXiflr1_-xxxxxxxxxxxxx
PAYPAL_SECRET=ELxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
PAYPAL_MODE=sandbox
```

⚠️ **QUAN TRỌNG**: Thêm `.env` vào `.gitignore`!

### ✅ Bước 4: Load .env trong main.dart (1 phút)
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(...);
  // ... rest of code
}
```

### ✅ Bước 5: Cập Nhật payment_service.dart (5 phút)

Thay thế hàm `processPayPalPayment` trong `lib/services/payment_service.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:paypal_payment/paypal_payment.dart';

static Future<PaymentResult> processPayPalPayment({
  required double amount,
  required String currency,
  required String description,
  required BuildContext context, // THÊM context
}) async {
  try {
    String clientId = dotenv.env['PAYPAL_CLIENT_ID'] ?? '';
    String secret = dotenv.env['PAYPAL_SECRET'] ?? '';
    String mode = dotenv.env['PAYPAL_MODE'] ?? 'sandbox';
    
    if (clientId.isEmpty || secret.isEmpty) {
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'PayPal chưa được cấu hình. Vui lòng kiểm tra .env file.',
      );
    }
    
    var item = PayPalItem(
      name: description,
      quantity: 1,
      currency: currency,
      price: amount.toStringAsFixed(2),
    );
    
    var paymentDetails = PayPalPaymentDetails(
      subtotal: amount.toStringAsFixed(2),
      shipping: '0.00',
      tax: '0.00',
    );
    
    var payment = PayPalPayment(
      amount: amount.toStringAsFixed(2),
      currency: currency,
      intent: PaymentIntent.sale,
      items: [item],
      paymentDetails: paymentDetails,
    );
    
    var result = await PayPalPaymentService().startPayment(
      context: context,
      clientId: clientId,
      secret: secret,
      environment: mode == 'sandbox'
          ? PayPalEnvironment.sandbox
          : PayPalEnvironment.production,
      payment: payment,
    );
    
    if (result != null && result.status == PaymentStatus.success) {
      return PaymentResult(
        success: true,
        transactionId: result.paymentId ?? 
            'PAYPAL_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Thanh toán PayPal thành công',
      );
    } else if (result != null && result.status == PaymentStatus.cancel) {
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Thanh toán đã bị hủy',
      );
    } else {
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Thanh toán PayPal thất bại',
      );
    }
  } catch (e) {
    return PaymentResult(
      success: false,
      transactionId: null,
      message: 'Lỗi: $e',
    );
  }
}
```

### ✅ Bước 6: Cập Nhật payment_screen.dart (2 phút)

Trong hàm `_handlePayment()`, thay đổi:

```dart
if (paymentMethod == PaymentMethod.paypal) {
  result = await PaymentService.processPayPalPayment(
    amount: widget.totalPrice,
    currency: 'USD', // PayPal thường dùng USD
    description: 'Đặt vé xem phim - ${widget.selectedSeats.length} ghế',
    context: context, // THÊM context
  );
}
```

### ✅ Bước 7: Test (5 phút)
1. Chạy app: `flutter run`
2. Chọn phim → Chọn ghế → Thanh toán
3. Chọn **PayPal**
4. PayPal sẽ mở → Đăng nhập với **Sandbox test account**
5. Xác nhận thanh toán

---

## 🔑 Lấy Sandbox Test Account

1. Vào PayPal Developer Portal
2. Tab **"Sandbox"** → **"Accounts"**
3. Nhấn **"Create Account"**
4. Chọn loại: **"Personal"** hoặc **"Business"**
5. Email và password sẽ được tạo tự động
6. **Lưu lại** để test!

---

## ⚠️ Lưu Ý Quan Trọng

1. **KHÔNG commit `.env`** vào Git
2. **Test với Sandbox** trước khi dùng Live
3. **Currency**: PayPal thường dùng USD, nếu dùng VND cần cấu hình thêm
4. **Package**: Có thể cần thử package khác nếu `paypal_payment` không hoạt động

---

## 🐛 Troubleshooting Nhanh

| Lỗi | Giải Pháp |
|-----|-----------|
| "Invalid Client ID" | Kiểm tra `.env` file, đảm bảo đã load trong `main.dart` |
| "Package not found" | Chạy `flutter pub get` |
| PayPal không mở | Kiểm tra context được truyền đúng, thử package khác |
| "Network error" | Kiểm tra internet, thử lại sau |

---

## 📚 Tài Liệu

- **Chi tiết đầy đủ**: Xem `PAYPAL_INTEGRATION_GUIDE.md`
- **Code examples**: Xem `PAYPAL_CODE_EXAMPLE.dart`
- **PayPal Docs**: https://developer.paypal.com/docs

