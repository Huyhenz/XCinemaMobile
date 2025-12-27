# Hướng Dẫn Tích Hợp PayPal - Từ Đăng Ký Đến Cấu Hình

## Mục Lục
1. [Đăng Ký Tài Khoản PayPal Developer](#1-đăng-ký-tài-khoản-paypal-developer)
2. [Tạo Ứng Dụng PayPal](#2-tạo-ứng-dụng-paypal)
3. [Lấy Credentials](#3-lấy-credentials)
4. [Cài Đặt Packages Flutter](#4-cài-đặt-packages-flutter)
5. [Cấu Hình Code](#5-cấu-hình-code)
6. [Test PayPal Integration](#6-test-paypal-integration)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Đăng Ký Tài Khoản PayPal Developer

### Bước 1.1: Truy cập PayPal Developer Portal
1. Mở trình duyệt và truy cập: **https://developer.paypal.com**
2. Nhấn nút **"Log In"** ở góc trên bên phải

### Bước 1.2: Đăng nhập hoặc Tạo tài khoản
- **Nếu đã có tài khoản PayPal**: Đăng nhập bằng email và mật khẩu
- **Nếu chưa có**: 
  1. Nhấn **"Sign Up"**
  2. Điền thông tin:
     - Email
     - Mật khẩu
     - Tên, Họ
     - Số điện thoại
     - Quốc gia
  3. Xác nhận email
  4. Hoàn tất đăng ký

### Bước 1.3: Xác thực tài khoản
- PayPal có thể yêu cầu xác thực danh tính
- Cung cấp thông tin cần thiết (nếu được yêu cầu)

---

## 2. Tạo Ứng Dụng PayPal

### Bước 2.1: Vào Dashboard
1. Sau khi đăng nhập, bạn sẽ thấy **Dashboard**
2. Nhấn vào **"My Apps & Credentials"** ở menu bên trái

### Bước 2.2: Tạo App mới
1. Trong phần **"REST API apps"**, nhấn **"Create App"**
2. Điền thông tin:
   - **App Name**: `XCinema Mobile App` (hoặc tên bạn muốn)
   - **Merchant**: Chọn merchant account (hoặc tạo mới)
   - **Sandbox/Live**: Chọn **"Sandbox"** (để test)
3. Nhấn **"Create App"**

### Bước 2.3: Chọn loại App
- Chọn **"Accept Payments"** hoặc **"Accept Payments & Manage Account"**
- Nhấn **"Create App"**

### Bước 2.4: Cấu Hình Payment Capabilities (QUAN TRỌNG)

Sau khi tạo app, bạn sẽ thấy trang cấu hình với các tùy chọn:

#### ✅ **Payment Capabilities - Nên chọn:**
- ✅ **Payment links and buttons**: Cần thiết để tích hợp thanh toán
- ✅ **Save payment methods**: Tùy chọn (để lưu thẻ cho lần sau)
- ✅ **Subscriptions**: Không cần cho đặt vé (chỉ cần nếu có gói đăng ký)

#### ❌ **Payment Capabilities - KHÔNG cần:**
- ❌ **Invoicing**: Không cần (chỉ dùng để gửi hóa đơn)
- ❌ **Payouts**: Không cần (chỉ dùng để chuyển tiền cho nhiều người)

#### ✅ **Add-on Services - Nên chọn:**
- ✅ **Transaction search**: Hữu ích để xem lịch sử giao dịch
- ✅ **Customer disputes**: Hữu ích để xử lý tranh chấp

#### ❌ **Add-on Services - KHÔNG cần:**
- ❌ **Log in with PayPal**: Không cần (app đã có authentication riêng)

#### ✅ **PayPal SDKs - Nên chọn:**
- ✅ **Mobile SDKs**: **BẮT BUỘC** - Cần để tích hợp vào Flutter app
- ❌ **JavaScript SDK v6**: Không cần (chỉ dùng cho web)

**Kết luận**: 
- **Tối thiểu**: Chọn "Payment links and buttons" và "Mobile SDKs"
- **Khuyến nghị**: Chọn thêm "Save payment methods", "Transaction search", "Customer disputes"
- **Không cần**: Invoicing, Payouts, Log in with PayPal, JavaScript SDK

---

## 3. Lấy Credentials

### Bước 3.1: Lấy Client ID và Secret
Sau khi tạo app, bạn sẽ thấy:
- **Client ID**: `AeA1QIZXiflr1_-...` (copy cái này)
- **Secret**: Nhấn **"Show"** để hiện Secret, sau đó copy

### Bước 3.2: Lưu Credentials an toàn
⚠️ **QUAN TRỌNG**: 
- **KHÔNG** commit credentials vào Git
- Lưu vào file `.env` hoặc sử dụng environment variables
- Sandbox credentials chỉ dùng cho testing

### Bước 3.3: Test với Sandbox Account
1. Vào **"Sandbox"** tab
2. Tạo test accounts:
   - **Personal Account**: Để test như người dùng
   - **Business Account**: Để test như merchant
3. Lưu email và password của test accounts

---

## 4. Cài Đặt Packages Flutter

### Bước 4.1: Thêm package vào pubspec.yaml

Mở file `pubspec.yaml` và thêm:

```yaml
dependencies:
  # ... existing dependencies ...
  
  # Payment Integration
  http: ^1.2.2  # Để gọi PayPal REST API
  url_launcher: ^6.3.1  # Để mở PayPal checkout URL
  webview_flutter: ^4.4.2  # Để hiển thị PayPal checkout trong app
  flutter_dotenv: ^5.1.0  # Để lưu credentials an toàn
```

**Lưu ý**: 
- Package `paypal_payment` không còn được maintain và không tương thích
- Chúng ta sẽ tích hợp PayPal trực tiếp qua REST API và WebView
- Điều này cho phép kiểm soát tốt hơn và tương thích với các phiên bản Flutter mới

### Bước 4.2: Cài đặt packages
```bash
flutter pub get
```

### Bước 4.3: Tạo file .env
Tạo file `.env` ở root project:

```env
# PayPal Sandbox Credentials
PAYPAL_CLIENT_ID=YOUR_PAYPAL_CLIENT_ID_HERE
PAYPAL_SECRET=YOUR_PAYPAL_SECRET_HERE
PAYPAL_MODE=sandbox  # hoặc 'live' cho production

# PayPal Live Credentials (khi deploy)
# PAYPAL_CLIENT_ID_LIVE=YOUR_LIVE_CLIENT_ID
# PAYPAL_SECRET_LIVE=YOUR_LIVE_SECRET
```

### Bước 4.4: Thêm .env vào .gitignore
Đảm bảo file `.env` không được commit:
```
.env
.env.local
```

---

## 5. Cấu Hình Code

### Bước 5.1: Cập nhật payment_service.dart

**Lưu ý quan trọng**: Package `paypal_payment` không còn được maintain. Chúng ta sẽ tích hợp PayPal qua REST API và WebView.

Mở `lib/services/payment_service.dart` và cập nhật để sử dụng PayPal REST API:

```dart
// File: lib/services/payment_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class PaymentService {
  // Load credentials from .env
  static String get _paypalClientId => dotenv.env['PAYPAL_CLIENT_ID'] ?? '';
  static String get _paypalSecret => dotenv.env['PAYPAL_SECRET'] ?? '';
  static String get _paypalBaseUrl => dotenv.env['PAYPAL_MODE'] == 'sandbox'
      ? 'https://api.sandbox.paypal.com'
      : 'https://api.paypal.com';

  /// Get PayPal Access Token
  static Future<String?> _getAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_paypalBaseUrl/v1/oauth2/token'),
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'en_US',
        },
        body: {
          'grant_type': 'client_credentials',
        },
        encoding: Encoding.getByName('utf-8'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      }
      return null;
    } catch (e) {
      print('❌ Error getting PayPal access token: $e');
      return null;
    }
  }

  /// Create PayPal Order
  static Future<Map<String, dynamic>?> _createOrder({
    required String accessToken,
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_paypalBaseUrl/v2/checkout/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'intent': 'CAPTURE',
          'purchase_units': [
            {
              'amount': {
                'currency_code': currency,
                'value': amount.toStringAsFixed(2),
              },
              'description': description,
            }
          ],
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error creating PayPal order: $e');
      return null;
    }
  }

  /// Process PayPal payment with real API
  static Future<PaymentResult> processPayPalPayment({
    required double amount,
    required String currency,
    required String description,
    required BuildContext context,
  }) async {
    try {
      print('💳 Processing PayPal payment: $amount $currency');
      
      // Step 1: Get access token
      String? accessToken = await _getAccessToken();
      if (accessToken == null) {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Không thể kết nối với PayPal. Vui lòng thử lại.',
        );
      }

      // Step 2: Create order
      Map<String, dynamic>? order = await _createOrder(
        accessToken: accessToken,
        amount: amount,
        currency: currency,
        description: description,
      );

      if (order == null) {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Không thể tạo đơn hàng PayPal. Vui lòng thử lại.',
        );
      }

      // Step 3: Get approval URL and open in WebView
      String? approvalUrl;
      for (var link in order['links'] ?? []) {
        if (link['rel'] == 'approve') {
          approvalUrl = link['href'];
          break;
        }
      }

      if (approvalUrl == null) {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Không thể lấy URL thanh toán PayPal.',
        );
      }

      // Step 4: Open PayPal checkout in WebView
      String? transactionId = await _showPayPalWebView(
        context: context,
        approvalUrl: approvalUrl,
        orderId: order['id'],
        accessToken: accessToken,
      );

      if (transactionId != null) {
        print('✅ PayPal payment successful: $transactionId');
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          message: 'Thanh toán PayPal thành công',
        );
      } else {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Thanh toán đã bị hủy hoặc thất bại.',
        );
      }
    } catch (e) {
      print('❌ PayPal payment error: $e');
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Lỗi xử lý thanh toán PayPal: $e',
      );
    }
  }

  /// Show PayPal checkout in WebView
  static Future<String?> _showPayPalWebView({
    required BuildContext context,
    required String approvalUrl,
    required String orderId,
    required String accessToken,
  }) async {
    final Completer<String?> completer = Completer<String?>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                // Check for success/cancel URLs
                if (url.contains('success') || url.contains('return')) {
                  // Capture the payment
                  _capturePayment(
                    accessToken: accessToken,
                    orderId: orderId,
                  ).then((result) {
                    if (result != null && result['status'] == 'COMPLETED') {
                      Navigator.of(context).pop();
                      completer.complete(result['purchase_units'][0]['payments']['captures'][0]['id']);
                    } else {
                      Navigator.of(context).pop();
                      completer.complete(null);
                    }
                  });
                } else if (url.contains('cancel')) {
                  Navigator.of(context).pop();
                  completer.complete(null);
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(approvalUrl));

        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                AppBar(
                  title: const Text('PayPal Checkout'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                      completer.complete(null);
                    },
                  ),
                ),
                Expanded(
                  child: WebViewWidget(controller: controller),
                ),
              ],
            ),
          ),
        );
      },
    );

    return completer.future;
  }

  /// Capture PayPal payment
  static Future<Map<String, dynamic>?> _capturePayment({
    required String accessToken,
    required String orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_paypalBaseUrl/v2/checkout/orders/$orderId/capture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error capturing PayPal payment: $e');
      return null;
    }
  }
}
    } catch (e) {
      print('❌ PayPal payment error: $e');
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Lỗi xử lý thanh toán PayPal: $e',
      );
    }
  }
}
```

### Bước 5.2: Load .env trong main.dart

Mở `lib/main.dart` và thêm:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize locale data for Vietnamese
  await initializeDateFormatting('vi_VN', null);

  runApp(const MyApp());
}
```

### Bước 5.3: Cập nhật payment_screen.dart

Cập nhật hàm `_handlePayment()` để truyền context:

```dart
Future<void> _handlePayment() async {
  setState(() => _isProcessing = true);

  try {
    PaymentMethod paymentMethod;
    switch (_selectedPaymentMethod) {
      case 'paypal':
        paymentMethod = PaymentMethod.paypal;
        break;
      // ... other cases
    }

    PaymentResult result;
    
    if (paymentMethod == PaymentMethod.paypal) {
      // PayPal cần context để mở UI
      result = await PaymentService.processPayPalPayment(
        amount: widget.totalPrice,
        currency: 'USD', // PayPal thường dùng USD
        description: 'Đặt vé xem phim - ${widget.selectedSeats.length} ghế',
        context: context, // Truyền context
      );
    } else {
      // Other payment methods...
      result = await PaymentService.processPayment(
        method: paymentMethod,
        amount: widget.totalPrice,
        description: 'Đặt vé xem phim - ${widget.selectedSeats.length} ghế',
        currency: 'VND',
      );
    }

    // ... rest of the code
  } catch (e) {
    // ... error handling
  }
}
```

### Bước 5.4: Cấu hình Android (nếu cần)

Mở `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        // ... existing config
        minSdkVersion 21 // PayPal yêu cầu tối thiểu API 21
    }
}
```

### Bước 5.5: Cấu hình iOS (nếu cần)

Mở `ios/Podfile`:

```ruby
platform :ios, '12.0' # PayPal yêu cầu iOS 12+
```

---

## 6. Test PayPal Integration

### Bước 6.1: Test với Sandbox Account

1. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```

2. **Test flow**:
   - Chọn phim → Chọn ghế → Thanh toán
   - Chọn **PayPal**
   - Nhấn **"XÁC NHẬN THANH TOÁN"**

3. **PayPal sẽ mở**:
   - WebView hoặc browser với PayPal login
   - Đăng nhập bằng **Sandbox test account** (đã tạo ở bước 3.3)
   - Xác nhận thanh toán

4. **Kết quả**:
   - Nếu thành công: Quay lại app với dialog thành công
   - Nếu hủy: Quay lại app với thông báo hủy

### Bước 6.2: Test Cases

#### Test Case 1: Payment Success
1. Chọn PayPal
2. Đăng nhập với sandbox account
3. Xác nhận thanh toán
4. **Expected**: Thành công, booking được tạo

#### Test Case 2: Payment Cancel
1. Chọn PayPal
2. Đăng nhập với sandbox account
3. Nhấn "Cancel" hoặc đóng PayPal
4. **Expected**: Quay lại app, không tạo booking

#### Test Case 3: Payment Error
1. Chọn PayPal
2. Đăng nhập với account không đủ tiền
3. **Expected**: Hiển thị lỗi, không tạo booking

### Bước 6.3: Kiểm tra Logs

Xem logs trong console:
- `💳 Processing PayPal payment`: Bắt đầu payment
- `✅ PayPal payment successful`: Thành công
- `❌ PayPal payment failed`: Thất bại

---

## 7. Troubleshooting

### Lỗi: "Invalid Client ID"
- **Nguyên nhân**: Client ID hoặc Secret sai
- **Giải pháp**: 
  1. Kiểm tra lại credentials trong `.env`
  2. Đảm bảo đã load `.env` trong `main.dart`
  3. Kiểm tra có dấu cách thừa trong `.env`

### Lỗi: "PayPal SDK not initialized"
- **Nguyên nhân**: Package chưa được cài đặt đúng
- **Giải pháp**: 
  1. Chạy `flutter pub get`
  2. Chạy `flutter clean` và `flutter pub get` lại
  3. Kiểm tra package trong `pubspec.yaml`

### Lỗi: "Network error" hoặc "Connection timeout"
- **Nguyên nhân**: Không kết nối được PayPal API
- **Giải pháp**:
  1. Kiểm tra internet connection
  2. Kiểm tra firewall/proxy
  3. Thử lại sau vài phút

### PayPal không mở
- **Nguyên nhân**: Context không đúng hoặc package issue
- **Giải pháp**:
  1. Đảm bảo truyền `context` đúng
  2. Kiểm tra package version
  3. Thử package khác: `flutter_paypal_native` hoặc `paypal_payment`

### Payment thành công nhưng không lưu vào database
- **Nguyên nhân**: Lỗi trong code xử lý sau payment
- **Giải pháp**:
  1. Kiểm tra logs để xem lỗi cụ thể
  2. Kiểm tra Firebase connection
  3. Kiểm tra `saveBooking` và `savePayment` functions

---

## 8. Chuyển Sang Production

### Bước 8.1: Tạo Live App
1. Vào PayPal Developer Portal
2. Tạo app mới với **"Live"** mode
3. Lấy Live credentials

### Bước 8.2: Cập nhật .env
```env
PAYPAL_CLIENT_ID=YOUR_LIVE_CLIENT_ID
PAYPAL_SECRET=YOUR_LIVE_SECRET
PAYPAL_MODE=live
```

### Bước 8.3: Test với tài khoản thật
- Test với số tiền nhỏ trước
- Đảm bảo webhook được cấu hình (nếu cần)
- Monitor transactions trong PayPal dashboard

---

## 9. Tài Liệu Tham Khảo

- **PayPal Developer Docs**: https://developer.paypal.com/docs
- **PayPal REST API**: https://developer.paypal.com/docs/api/overview/
- **PayPal Flutter Package**: https://pub.dev/packages/paypal_payment
- **PayPal Sandbox Testing**: https://developer.paypal.com/docs/api-basics/sandbox/

---

## 10. Checklist

Trước khi deploy:
- [ ] Đã tạo PayPal Developer account
- [ ] Đã tạo Sandbox app và lấy credentials
- [ ] Đã cài đặt packages
- [ ] Đã tạo file `.env` và thêm vào `.gitignore`
- [ ] Đã load `.env` trong `main.dart`
- [ ] Đã cập nhật `payment_service.dart`
- [ ] Đã test với Sandbox account
- [ ] Đã test các trường hợp: success, cancel, error
- [ ] Đã kiểm tra logs và database
- [ ] Đã chuẩn bị Live credentials (khi deploy)

---

## Lưu Ý Quan Trọng

1. **KHÔNG commit `.env` file** vào Git
2. **Luôn test với Sandbox** trước khi dùng Live
3. **Monitor transactions** trong PayPal dashboard
4. **Xử lý webhooks** để verify payments (recommended)
5. **Bảo mật credentials** - không share công khai

