// // File: PAYPAL_CODE_EXAMPLE.dart
// // Đây là file example code để tham khảo khi tích hợp PayPal thực tế
// // Copy code này vào payment_service.dart sau khi đã cấu hình PayPal
//
// /*
//  * CÁCH 1: Sử dụng package paypal_payment
//  *
//  * Bước 1: Thêm vào pubspec.yaml
//  * dependencies:
//  *   paypal_payment: ^1.0.6
//  *   flutter_dotenv: ^5.1.0
//  *
//  * Bước 2: Tạo file .env ở root project
//  * PAYPAL_CLIENT_ID=your_client_id_here
//  * PAYPAL_SECRET=your_secret_here
//  * PAYPAL_MODE=sandbox
//  *
//  * Bước 3: Load .env trong main.dart
//  * import 'package:flutter_dotenv/flutter_dotenv.dart';
//  *
//  * void main() async {
//  *   WidgetsFlutterBinding.ensureInitialized();
//  *   await dotenv.load(fileName: ".env");
//  *   // ... rest of code
//  * }
//  */
//
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// // Uncomment khi đã cài package:
// // import 'package:paypal_payment/paypal_payment.dart';
//
// class PayPalPaymentExample {
//   // Lấy credentials từ .env
//   static String get clientId => dotenv.env['PAYPAL_CLIENT_ID'] ?? '';
//   static String get secret => dotenv.env['PAYPAL_SECRET'] ?? '';
//   static String get mode => dotenv.env['PAYPAL_MODE'] ?? 'sandbox';
//
//   /// Example: Process PayPal payment với package paypal_payment
//   static Future<Map<String, dynamic>> processPayment({
//     required BuildContext context,
//     required double amount,
//     required String currency,
//     required String description,
//   }) async {
//     try {
//       // Tạo PayPal item
//       var item = PayPalItem(
//         name: description,
//         quantity: 1,
//         currency: currency,
//         price: amount.toStringAsFixed(2),
//       );
//
//       // Tạo payment details
//       var paymentDetails = PayPalPaymentDetails(
//         subtotal: amount.toStringAsFixed(2),
//         shipping: '0.00',
//         tax: '0.00',
//       );
//
//       // Tạo payment
//       var payment = PayPalPayment(
//         amount: amount.toStringAsFixed(2),
//         currency: currency,
//         intent: PaymentIntent.sale,
//         items: [item],
//         paymentDetails: paymentDetails,
//       );
//
//       // Process payment
//       var result = await PayPalPaymentService().startPayment(
//         context: context,
//         clientId: clientId,
//         secret: secret,
//         environment: mode == 'sandbox'
//             ? PayPalEnvironment.sandbox
//             : PayPalEnvironment.production,
//         payment: payment,
//       );
//
//       if (result != null && result.status == PaymentStatus.success) {
//         return {
//           'success': true,
//           'transactionId': result.paymentId,
//           'message': 'Thanh toán thành công',
//         };
//       } else if (result != null && result.status == PaymentStatus.cancel) {
//         return {
//           'success': false,
//           'transactionId': null,
//           'message': 'Thanh toán đã bị hủy',
//         };
//       } else {
//         return {
//           'success': false,
//           'transactionId': null,
//           'message': 'Thanh toán thất bại',
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'transactionId': null,
//         'message': 'Lỗi: $e',
//       };
//     }
//   }
// }
//
// /*
//  * CÁCH 2: Sử dụng PayPal REST API trực tiếp (không cần package)
//  *
//  * Bước 1: Thêm vào pubspec.yaml
//  * dependencies:
//  *   http: ^1.2.2
//  *   flutter_dotenv: ^5.1.0
//  *
//  * Bước 2: Tạo backend endpoint để xử lý payment (recommended)
//  * Hoặc gọi trực tiếp từ Flutter (không recommended cho production)
//  */
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class PayPalRestAPIExample {
//   static String get clientId => dotenv.env['PAYPAL_CLIENT_ID'] ?? '';
//   static String get secret => dotenv.env['PAYPAL_SECRET'] ?? '';
//   static String get baseUrl => dotenv.env['PAYPAL_MODE'] == 'sandbox'
//       ? 'https://api.sandbox.paypal.com'
//       : 'https://api.paypal.com';
//
//   /// Step 1: Get Access Token
//   static Future<String?> getAccessToken() async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/v1/oauth2/token'),
//         headers: {
//           'Accept': 'application/json',
//           'Accept-Language': 'en_US',
//         },
//         body: {
//           'grant_type': 'client_credentials',
//         },
//         encoding: Encoding.getByName('utf-8'),
//       ).timeout(const Duration(seconds: 30));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['access_token'];
//       }
//       return null;
//     } catch (e) {
//       print('Error getting access token: $e');
//       return null;
//     }
//   }
//
//   /// Step 2: Create Order
//   static Future<Map<String, dynamic>?> createOrder({
//     required String accessToken,
//     required double amount,
//     required String currency,
//     required String description,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/v2/checkout/orders'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $accessToken',
//         },
//         body: json.encode({
//           'intent': 'CAPTURE',
//           'purchase_units': [
//             {
//               'amount': {
//                 'currency_code': currency,
//                 'value': amount.toStringAsFixed(2),
//               },
//               'description': description,
//             }
//           ],
//         }),
//       );
//
//       if (response.statusCode == 201) {
//         return json.decode(response.body);
//       }
//       return null;
//     } catch (e) {
//       print('Error creating order: $e');
//       return null;
//     }
//   }
//
//   /// Step 3: Capture Payment
//   static Future<Map<String, dynamic>?> capturePayment({
//     required String accessToken,
//     required String orderId,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/v2/checkout/orders/$orderId/capture'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $accessToken',
//         },
//       );
//
//       if (response.statusCode == 201) {
//         return json.decode(response.body);
//       }
//       return null;
//     } catch (e) {
//       print('Error capturing payment: $e');
//       return null;
//     }
//   }
// }
//
// /*
//  * CÁCH 3: Sử dụng WebView để mở PayPal Checkout
//  *
//  * Bước 1: Thêm vào pubspec.yaml
//  * dependencies:
//  *   webview_flutter: ^4.4.2
//  *   url_launcher: ^6.3.1
//  *
//  * Bước 2: Tạo PayPal checkout URL từ backend
//  * Bước 3: Mở URL trong WebView
//  */
//
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class PayPalWebViewExample {
//   /// Mở PayPal checkout trong WebView
//   static Widget buildPayPalWebView({
//     required String checkoutUrl,
//     required Function(String) onSuccess,
//     required Function() onCancel,
//   }) {
//     final controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageFinished: (String url) {
//             // Kiểm tra URL để xác định success/cancel
//             if (url.contains('success')) {
//               // Extract transaction ID từ URL
//               final uri = Uri.parse(url);
//               final transactionId = uri.queryParameters['transactionId'];
//               if (transactionId != null) {
//                 onSuccess(transactionId);
//               }
//             } else if (url.contains('cancel')) {
//               onCancel();
//             }
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(checkoutUrl));
//
//     return WebViewWidget(controller: controller);
//   }
//
//   /// Hoặc mở trong browser
//   static Future<void> openPayPalInBrowser(String checkoutUrl) async {
//     final uri = Uri.parse(checkoutUrl);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }
// }
//
