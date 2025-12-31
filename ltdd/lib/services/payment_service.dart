// File: lib/services/payment_service.dart
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:pay/pay.dart';
import 'package:crypto/crypto.dart';
import '../screens/payment_success_screen.dart';
import '../screens/payment_failure_screen.dart';
import '../screens/google_pay_screen.dart';

enum PaymentMethod {
  paypal,
  vnpay, // VNPay - Cổng thanh toán Việt Nam
  zaloPay,
}

class PaymentService {
  // Load PayPal credentials from .env file
  static String get _paypalClientId {
    try {
      return dotenv.env['PAYPAL_CLIENT_ID'] ?? '';
    } catch (e) {
      print('⚠️ Error accessing PAYPAL_CLIENT_ID: $e');
      return '';
    }
  }
  
  static String get _paypalSecret {
    try {
      return dotenv.env['PAYPAL_SECRET'] ?? '';
    } catch (e) {
      print('⚠️ Error accessing PAYPAL_SECRET: $e');
      return '';
    }
  }
  
  static String get _paypalMode {
    try {
      return dotenv.env['PAYPAL_MODE'] ?? 'sandbox';
    } catch (e) {
      print('⚠️ Error accessing PAYPAL_MODE: $e');
      return 'sandbox';
    }
  }
  
  static String get _paypalBaseUrl => _paypalMode == 'sandbox'
      ? 'https://api.sandbox.paypal.com'
      : 'https://api.paypal.com';
  
  // Load Stripe credentials from .env file
  static String get _stripeSecretKey {
    try {
      return dotenv.env['STRIPE_SECRET_KEY'] ?? '';
    } catch (e) {
      print('⚠️ Error accessing STRIPE_SECRET_KEY: $e');
      return '';
    }
  }
  
  static String get _stripePublishableKey {
    try {
      return dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    } catch (e) {
      // Try to get from config file if not in .env
      return 'pk_test_51SkM1bF20g1EMWhNaiY1VdKBusVJorFYNwIJlV1GthsJdAtqoTerkr8R6ZVMVN0QVAzCqJ1QHjRATDWLakRaSR8g00rBaSQuJa';
    }
  }
  
  static String get _stripeBaseUrl => 'https://api.stripe.com/v1';
  
  // Load VNPay credentials from .env file
  static String get _vnpayTmnCode {
    try {
      return dotenv.env['VNPAY_TMN_CODE'] ?? '';
    } catch (e) {
      print('⚠️ Error accessing VNPAY_TMN_CODE: $e');
      return '';
    }
  }
  
  static String get _vnpayHashSecret {
    try {
      return dotenv.env['VNPAY_HASH_SECRET'] ?? '';
    } catch (e) {
      print('⚠️ Error accessing VNPAY_HASH_SECRET: $e');
      return '';
    }
  }
  
  static String get _vnpayBaseUrl {
    // Use custom base URL from .env if provided, otherwise use default
    final customUrl = dotenv.env['VNPAY_BASE_URL'];
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }
    // Default URLs
    return dotenv.env['VNPAY_MODE'] == 'production'
        ? 'https://www.vnpay.vn'
        : 'https://sandbox.vnpayment.vn';
  }
  
  // Load ZaloPay credentials from .env file
  static String get _zaloPayAppId {
    try {
      return dotenv.env['ZALOPAY_APP_ID'] ?? '';
    } catch (e) {
      print('⚠️ Error accessing ZALOPAY_APP_ID: $e');
      return '';
    }
  }
  
  static String get _zaloPayKey1 {
    try {
      return dotenv.env['ZALOPAY_KEY1'] ?? '';
    } catch (e) {
      print('⚠️ Error accessing ZALOPAY_KEY1: $e');
      return '';
    }
  }
  
  static String get _zaloPayKey2 {
    try {
      return dotenv.env['ZALOPAY_KEY2'] ?? '';
    } catch (e) {
      print('⚠️ Error accessing ZALOPAY_KEY2: $e');
      return '';
    }
  }
  
  static String get _zaloPayBaseUrl => dotenv.env['ZALOPAY_MODE'] == 'production'
      ? 'https://openapi.zalopay.vn'
      : 'https://sb-openapi.zalopay.vn';
  
  // ZaloPay credentials (for testing)
  // Replace with your actual ZaloPay credentials when integrating real API
  // static const String _zaloPayAppId = 'YOUR_ZALOPAY_APP_ID';
  // static const String _zaloPayKey1 = 'YOUR_ZALOPAY_KEY1';
  // static const String _zaloPayKey2 = 'YOUR_ZALOPAY_KEY2';
  // static const String _zaloPayBaseUrl = 'https://sandbox.zalopay.com.vn'; // Sandbox URL

  /// Get PayPal Access Token
  static Future<String?> _getPayPalAccessToken() async {
    try {
      print('🔑 Getting PayPal access token...');
      
      if (_paypalClientId.isEmpty || _paypalSecret.isEmpty) {
        print('⚠️ PayPal credentials not found in .env file');
        print('   Client ID empty: ${_paypalClientId.isEmpty}');
        print('   Secret empty: ${_paypalSecret.isEmpty}');
        return null;
      }

      print('   Client ID: ${_paypalClientId.substring(0, _paypalClientId.length > 10 ? 10 : _paypalClientId.length)}...');
      print('   Base URL: $_paypalBaseUrl');
      
      final credentials = base64Encode(utf8.encode('$_paypalClientId:$_paypalSecret'));
      
      final response = await http.post(
        Uri.parse('$_paypalBaseUrl/v1/oauth2/token'),
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'en_US',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type': 'client_credentials',
        },
      ).timeout(const Duration(seconds: 30));

      print('   Token response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'];
        if (token != null) {
          print('✅ PayPal access token obtained successfully');
          return token;
        } else {
          print('❌ Access token not found in response');
          return null;
        }
      } else {
        print('❌ Failed to get PayPal access token: ${response.statusCode}');
        print('Response: ${response.body}');
        
        // Check for common errors
        if (response.statusCode == 401) {
          print('💡 Authentication failed. Check your Client ID and Secret.');
        } else if (response.statusCode == 400) {
          print('💡 Bad request. Check your credentials format.');
        }
        
        return null;
      }
    } catch (e) {
      print('❌ Error getting PayPal access token: $e');
      print('Error type: ${e.runtimeType}');
      if (e.toString().contains('TimeoutException')) {
        print('💡 Request timed out. Check internet connection.');
      } else if (e.toString().contains('SocketException')) {
        print('💡 Network error. Check internet connection.');
      }
      return null;
    }
  }

  /// Create PayPal Order
  static Future<Map<String, dynamic>?> _createPayPalOrder({
    required String accessToken,
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      print('📦 Creating PayPal order...');
      print('   Amount: $amount $currency');
      print('   Description: $description');
      print('   Base URL: $_paypalBaseUrl');
      
      // PayPal doesn't support VND, need to convert or use USD
      String paypalCurrency = currency;
      double paypalAmount = amount;
      
      // Convert VND to USD if currency is VND (PayPal sandbox supports USD)
      if (currency == 'VND') {
        // Approximate conversion: 1 USD = 24,000 VND (adjust as needed)
        paypalAmount = amount / 24000;
        paypalCurrency = 'USD';
        print('   ⚠️ Converted VND to USD: $amount VND = ${paypalAmount.toStringAsFixed(2)} USD');
      }
      
      final requestBody = {
        'intent': 'CAPTURE',
        'purchase_units': [
          {
            'amount': {
              'currency_code': paypalCurrency,
              'value': paypalAmount.toStringAsFixed(2),
            },
            'description': description,
          }
        ],
          'application_context': {
            // Return URLs - PayPal will redirect here after payment approval/cancel
            // PayPal will append ?token=ORDER_ID&PayerID=PAYER_ID to return_url
            // Using custom URLs so we can detect when payment is successful
            'return_url': 'https://xcinema.app/payment/success',
            'cancel_url': 'https://xcinema.app/payment/cancel',
            'user_action': 'PAY_NOW',
            'brand_name': 'XCinema',
            'landing_page': 'LOGIN', // Force login page every time (don't save session)
            'shipping_preference': 'NO_SHIPPING', // No shipping for movie tickets
          },
      };
      
      print('   Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$_paypalBaseUrl/v2/checkout/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 201) {
        final orderData = json.decode(response.body);
        print('✅ PayPal order created: ${orderData['id']}');
        return orderData;
      } else {
        print('❌ Failed to create PayPal order: ${response.statusCode}');
        print('Response: ${response.body}');
        
        // Try to parse error message
        try {
          final errorData = json.decode(response.body);
          if (errorData['details'] != null) {
            print('Error details: ${errorData['details']}');
          }
          if (errorData['message'] != null) {
            print('Error message: ${errorData['message']}');
          }
        } catch (e) {
          // Ignore parse error
        }
        
        return null;
      }
    } catch (e) {
      print('❌ Error creating PayPal order: $e');
      print('Error type: ${e.runtimeType}');
      if (e.toString().contains('TimeoutException')) {
        print('💡 Request timed out. Check internet connection.');
      } else if (e.toString().contains('SocketException')) {
        print('💡 Network error. Check internet connection.');
      }
      return null;
    }
  }

  /// Capture PayPal Payment
  static Future<Map<String, dynamic>?> _capturePayPalPayment({
    required String accessToken,
    required String orderId,
  }) async {
    try {
      print('💰 Capturing PayPal payment for order: $orderId');
      
      final response = await http.post(
        Uri.parse('$_paypalBaseUrl/v2/checkout/orders/$orderId/capture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('   Capture response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Payment captured successfully');
        return result;
      } else {
        print('❌ Failed to capture PayPal payment: ${response.statusCode}');
        print('Response: ${response.body}');
        
        // Parse error details
        try {
          final errorData = json.decode(response.body);
          if (errorData['details'] != null) {
            final details = errorData['details'] as List;
            for (var detail in details) {
              print('   Error issue: ${detail['issue']}');
              print('   Error description: ${detail['description']}');
            }
          }
        } catch (e) {
          // Ignore parse error
        }
        
        return null;
      }
    } catch (e) {
      print('❌ Error capturing PayPal payment: $e');
      print('Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Show PayPal checkout in WebView
  static Future<String?> _showPayPalWebView({
    required BuildContext context,
    required String approvalUrl,
    required String orderId,
    required String accessToken,
  }) async {
    try {
      final Completer<String?> completer = Completer<String?>();
      bool paymentCaptured = false;
      
      if (!context.mounted) {
        completer.complete(null);
        return completer.future;
      }

      // Check if dotenv is loaded before proceeding
      try {
        final testClientId = dotenv.env['PAYPAL_CLIENT_ID'];
        if (testClientId == null || testClientId.isEmpty) {
          print('⚠️ PayPal credentials not found in .env');
          completer.complete(null);
          return completer.future;
        }
      } catch (e) {
        print('❌ dotenv not initialized: $e');
        completer.complete(null);
        return completer.future;
      }

      // Force login mode: landing_page=LOGIN in application_context will force login page
      print('🔐 Force login mode enabled: PayPal will require login every time');
      print('🧹 Clearing PayPal cookies at system level...');

      // Clear cookies at system level BEFORE creating WebView
      // This is more effective than WebView-level clearing
      try {
        final cookieManager = PlatformWebViewCookieManager(
          const PlatformWebViewCookieManagerCreationParams(),
        );
        final hadCookies = await cookieManager.clearCookies();
        if (hadCookies) {
          print('✅ Cleared PayPal cookies at system level');
        } else {
          print('ℹ️ No cookies found to clear');
        }
      } catch (e) {
        print('⚠️ Could not clear cookies at system level: $e');
        // Continue anyway - will try other methods
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          // Create NEW WebViewController each time (don't reuse)
          // This ensures fresh session every time
          final controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..enableZoom(false)
            ..setBackgroundColor(Colors.white);
          
          // Clear cache and localStorage on Android BEFORE loading
          // Note: clearCookies() is not available in the API, but clearCache() and clearLocalStorage()
          // combined with URL parameters (force_reauthentication) should force fresh login
          if (controller.platform is AndroidWebViewController) {
            AndroidWebViewController.enableDebugging(false);
            final androidController = controller.platform as AndroidWebViewController;
            androidController
              ..clearCache()
              ..clearLocalStorage();
            print('✅ Cleared Android WebView cache and localStorage');
          }
          
          // Clear cache and localStorage on iOS BEFORE loading
          // Note: clearCookies() is not available in the API, but clearCache() and clearLocalStorage()
          // combined with URL parameters (force_reauthentication) should force fresh login
          if (controller.platform is WebKitWebViewController) {
            final webkitController = controller.platform as WebKitWebViewController;
            webkitController.clearCache();
            webkitController.clearLocalStorage();
            print('✅ Cleared iOS WebView cache and localStorage');
          }
          
          controller.setNavigationDelegate(
            NavigationDelegate(
              onWebResourceError: (WebResourceError error) {
                print('❌ WebView resource error: ${error.description} (code: ${error.errorCode})');
                // Handle WebView crash
                if (error.errorCode == -1 || error.description.contains('net::ERR_')) {
                  print('💥 WebView crashed or network error detected');
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (context.mounted && !completer.isCompleted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (ctx) => PaymentFailureScreen(
                          message: 'Lỗi kết nối với PayPal. Vui lòng thử lại.',
                          isCancelled: false,
                        ),
                      ),
                    );
                  }
                  if (!completer.isCompleted) {
                    completer.complete(null);
                  }
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                final url = request.url;
                print('🌐 PayPal WebView navigation: $url');
                
                // Parse URL to check for approval/cancel parameters
                final uri = Uri.parse(url);
                final token = uri.queryParameters['token'];
                final payerId = uri.queryParameters['PayerID'];
                final paymentId = uri.queryParameters['paymentId'];
                
                // Check for PayPal errors first
                if (url.contains('/genericError') || url.contains('/error')) {
                  final errorCode = uri.queryParameters['code'];
                  print('⚠️ PayPal error detected: $errorCode');
                  
                  if (errorCode == 'Q0FOTk9UX1BBWV9TRUxG' || errorCode == 'CANNOT_PAY_SELF') {
                    print('❌ Cannot pay self - merchant and payer are the same account');
                    print('💡 Use a different PayPal sandbox account to test payment');
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); // Close WebView dialog
                  }
                  // Navigate to failure screen - payment error, no booking to process
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (ctx) => PaymentFailureScreen(
                          message: 'Không thể thanh toán. Vui lòng sử dụng tài khoản PayPal khác.',
                          isCancelled: false,
                        ),
                      ),
                    );
                  }
                    completer.complete(null);
                    return NavigationDecision.prevent;
                  }
                  
                  // Other errors - treat as cancel
                  print('❌ PayPal error, treating as cancel');
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); // Close WebView dialog
                  }
                  // Navigate to failure screen - payment error, no booking to process
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (ctx) => PaymentFailureScreen(
                          message: 'Có lỗi xảy ra trong quá trình thanh toán.',
                          isCancelled: false,
                        ),
                      ),
                    );
                  }
                  completer.complete(null);
                  return NavigationDecision.prevent;
                }
                
                // IMPORTANT: Only detect approval when we have actual approval confirmation
                // PayPal checkout URL has token but that's NOT approval yet
                // Approval happens when user clicks "Pay Now" and PayPal redirects to return URL
                bool hasApprovalToken = token != null && token.isNotEmpty;
                bool hasPayerId = payerId != null && payerId.isNotEmpty;
                
                // Check if this is a return/approval URL AFTER user approved
                // PayPal redirects to our return_url after approval with token and PayerID
                // Our return URL: https://xcinema.app/payment/success?token=ORDER_ID&PayerID=PAYER_ID
                bool isReturnUrl = (url.contains('xcinema.app/payment/success') || 
                                   url.contains('/payment/success')) &&
                                  payerId != null && payerId.isNotEmpty;
                
                // Only treat as approval if:
                // 1. We have PayerID (user has approved) AND
                // 2. It's our return URL (PayPal redirected to our success URL)
                // 3. NOT an error page
                // 4. Haven't captured yet
                bool isApproval = hasPayerId && 
                                  isReturnUrl &&
                                  !url.contains('/genericError') &&
                                  !url.contains('/error') &&
                                  !paymentCaptured;
                
                print('   Token: ${token ?? 'none'}');
                print('   PayerID: ${payerId ?? 'none'}');
                print('   Is return URL: $isReturnUrl');
                print('   Is approval: $isApproval');
                
                if (isApproval && !paymentCaptured) {
                  paymentCaptured = true;
                  print('✅ PayPal approval detected (token: $token, PayerID: $payerId), capturing payment...');
                  
                  // Capture the payment immediately
                  _capturePayPalPayment(
                    accessToken: accessToken,
                    orderId: orderId,
                  ).then((result) {
                    if (result != null && result['status'] == 'COMPLETED') {
                      final purchaseUnits = result['purchase_units'] as List?;
                      if (purchaseUnits != null && purchaseUnits.isNotEmpty) {
                        final payments = purchaseUnits[0]['payments'] as Map?;
                        if (payments != null) {
                          final captures = payments['captures'] as List?;
                          if (captures != null && captures.isNotEmpty) {
                            final captureId = captures[0]['id'] as String?;
                            print('✅ PayPal payment captured: $captureId');
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(); // Close WebView dialog
                            }
                            // Don't navigate here - let payment_screen.dart handle navigation after processing booking
                            if (!completer.isCompleted) {
                              completer.complete(captureId ?? orderId);
                            }
                            return;
                          }
                        }
                      }
                      // Fallback to orderId if capture ID not found
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(); // Close WebView dialog
                      }
                      // Don't navigate here - let payment_screen.dart handle navigation after processing booking
                      if (!completer.isCompleted) {
                        completer.complete(orderId);
                      }
                    } else {
                      print('❌ PayPal capture failed: ${result?['status']}');
                      if (result != null && result['details'] != null) {
                        print('Error details: ${result['details']}');
                      }
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(); // Close WebView dialog
                      }
                      // Navigate to failure screen - payment failed, no booking to process
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (ctx) => PaymentFailureScreen(
                              message: 'Thanh toán không thể được xử lý. Vui lòng thử lại.',
                              isCancelled: false,
                            ),
                          ),
                        );
                      }
                      if (!completer.isCompleted) {
                        completer.complete(null);
                      }
                    }
                  }).catchError((error) {
                    print('❌ Error capturing PayPal payment: $error');
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(); // Close WebView dialog
                    }
                    // Navigate to failure screen - payment error, no booking to process
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (ctx) => PaymentFailureScreen(
                            message: 'Lỗi xử lý thanh toán: $error',
                            isCancelled: false,
                          ),
                        ),
                      );
                    }
                    if (!completer.isCompleted) {
                      completer.complete(null);
                    }
                  });
                  
                  // Prevent navigation to return URL (we handle it ourselves)
                  return NavigationDecision.prevent;
                }
                
                // Check if user cancelled - detect our cancel URL
                // Our cancel URL: https://xcinema.app/payment/cancel
                bool isCancelUrl = url.contains('xcinema.app/payment/cancel') || 
                                  url.contains('/payment/cancel');
                
                if (isCancelUrl && !paymentCaptured) {
                  print('❌ PayPal payment cancelled by user');
                  print('   Cancel URL: $url');
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); // Close WebView dialog
                  }
                  // Navigate to failure screen - user cancelled, no booking to process
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (ctx) => PaymentFailureScreen(
                          message: 'Bạn đã hủy giao dịch thanh toán.',
                          isCancelled: true,
                        ),
                      ),
                    );
                  }
                  if (!completer.isCompleted) {
                    completer.complete(null);
                  }
                  return NavigationDecision.prevent;
                }
                
                // Allow all other navigations (login pages, approval pages, etc.)
                // Don't interfere with PayPal's normal flow
                return NavigationDecision.navigate;
              },
              onPageFinished: (String url) {
                print('📄 PayPal page finished loading: $url');
                
                // Backup detection for approval (only if navigation didn't catch it)
                // IMPORTANT: Don't detect approval on checkout page - only on return URL after approval
                if (!paymentCaptured) {
                  final uri = Uri.parse(url);
                  final token = uri.queryParameters['token'];
                  final payerId = uri.queryParameters['PayerID'];
                  
                  // Only detect approval if:
                  // 1. We have PayerID (user has approved) AND
                  // 2. It's our return URL (PayPal redirected to our success URL)
                  // 3. NOT an error page
                  bool hasPayerId = payerId != null && payerId.isNotEmpty;
                  bool isReturnUrl = (url.contains('xcinema.app/payment/success') || 
                                     url.contains('/payment/success')) &&
                                    hasPayerId;
                  
                  if (hasPayerId && isReturnUrl && !url.contains('/genericError') && !url.contains('/error')) {
                    print('✅ Approval detected on page finished (backup)');
                    print('   Token: $token, PayerID: $payerId');
                    paymentCaptured = true;
                    
                    // Capture payment
                    _capturePayPalPayment(
                      accessToken: accessToken,
                      orderId: orderId,
                    ).then((result) {
                      if (result != null && result['status'] == 'COMPLETED') {
                        final purchaseUnits = result['purchase_units'] as List?;
                        if (purchaseUnits != null && purchaseUnits.isNotEmpty) {
                          final payments = purchaseUnits[0]['payments'] as Map?;
                          if (payments != null) {
                            final captures = payments['captures'] as List?;
                            if (captures != null && captures.isNotEmpty) {
                              final captureId = captures[0]['id'] as String?;
                              print('✅ PayPal payment captured: $captureId');
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(); // Close WebView dialog
                              }
                              // Don't navigate here - let payment_screen.dart handle navigation after processing booking
                              if (!completer.isCompleted) {
                                completer.complete(captureId ?? orderId);
                              }
                              return;
                            }
                          }
                        }
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(); // Close WebView dialog
                        }
                        // Don't navigate here - let payment_screen.dart handle navigation after processing booking
                        if (!completer.isCompleted) {
                          completer.complete(orderId);
                        }
                      } else {
                        print('❌ PayPal capture failed: ${result?['status']}');
                        if (result != null && result['details'] != null) {
                          print('Error details: ${result['details']}');
                        }
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(); // Close WebView dialog
                        }
                        // Navigate to failure screen - payment failed, no booking to process
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (ctx) => PaymentFailureScreen(
                                message: 'Thanh toán không thể được xử lý. Vui lòng thử lại.',
                                isCancelled: false,
                              ),
                            ),
                          );
                        }
                        if (!completer.isCompleted) {
                          completer.complete(null);
                        }
                      }
                    }).catchError((error) {
                      print('❌ Error capturing PayPal payment: $error');
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(); // Close WebView dialog
                      }
                      // Navigate to failure screen - payment error, no booking to process
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (ctx) => PaymentFailureScreen(
                              message: 'Lỗi xử lý thanh toán: $error',
                              isCancelled: false,
                            ),
                          ),
                        );
                      }
                      if (!completer.isCompleted) {
                        completer.complete(null);
                      }
                    });
                  }
                }
              },
            ),
          );
          
          // Modify approval URL to force logout/login
          // Add parameters to ensure fresh login every time
          final approvalUri = Uri.parse(approvalUrl);
          
          // Remove any existing session parameters that might preserve login
          final cleanParams = Map<String, String>.from(approvalUri.queryParameters);
          cleanParams.remove('remember_me');
          cleanParams.remove('session_id');
          cleanParams.remove('login_session_id');
          
          // Add parameters to force fresh login
          // These parameters tell PayPal to show login page even if cookies exist
          final modifiedUrl = approvalUri.replace(
            queryParameters: {
              ...cleanParams,
              // Force login page (PayPal will show login even if session exists)
              'force_reauthentication': 'true',
              // Don't remember login
              'remember_me': 'false',
              // Force logout before login
              'logout': 'true',
              // Add timestamp to prevent caching
              '_t': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );
          
          print('🔐 Loading PayPal with force login (cleared cookies/cache/localStorage)');
          print('   URL: ${modifiedUrl.toString()}');
          
          // Load checkout URL directly - URL parameters (logout=true, force_reauthentication=true) 
          // will handle logout and force fresh login
          print('🔐 Loading PayPal checkout page...');
          controller.loadRequest(modifiedUrl);

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'PayPal Checkout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(); // Close WebView dialog
                          }
                          // Navigate to failure screen - user closed WebView, no booking to process
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (ctx) => PaymentFailureScreen(
                                  message: 'Bạn đã đóng cửa sổ thanh toán.',
                                  isCancelled: true,
                                ),
                              ),
                            );
                          }
                          completer.complete(null);
                        },
                      ),
                    ],
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
    } catch (e) {
      print('❌ Error showing PayPal WebView: $e');
      print('Error type: ${e.runtimeType}');
      if (e.toString().contains('NotInitialized')) {
        print('💡 WebView or dotenv may not be initialized. Checking...');
        // Check if dotenv is loaded
        try {
          final clientId = dotenv.env['PAYPAL_CLIENT_ID'];
          print('✅ dotenv is accessible, Client ID: ${clientId?.substring(0, 10) ?? 'NOT FOUND'}...');
        } catch (dotenvError) {
          print('❌ dotenv error: $dotenvError');
        }
      }
      return null;
    }
  }

  /// Process PayPal payment with real API
  /// Returns payment result with transaction ID
  static Future<PaymentResult> processPayPalPayment({
    required double amount,
    required String currency,
    required String description,
    required BuildContext context,
  }) async {
    try {
      print('💳 Processing PayPal payment: $amount $currency');
      
      // Check if credentials are available
      if (_paypalClientId.isEmpty || _paypalSecret.isEmpty) {
        print('⚠️ PayPal credentials not configured. Using mock payment.');
        // Fallback to mock payment for testing
        await Future.delayed(const Duration(seconds: 2));
        bool success = DateTime.now().millisecond % 10 != 0;
        if (success) {
          String transactionId = 'PAYPAL_MOCK_${DateTime.now().millisecondsSinceEpoch}';
          return PaymentResult(
            success: true,
            transactionId: transactionId,
            message: 'Thanh toán PayPal thành công (Mock)',
          );
        } else {
          return PaymentResult(
            success: false,
            transactionId: null,
            message: 'Thanh toán PayPal thất bại. Vui lòng thử lại.',
          );
        }
      }

      // Step 1: Get access token
      String? accessToken = await _getPayPalAccessToken();
      if (accessToken == null) {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Không thể kết nối với PayPal. Vui lòng thử lại.',
        );
      }

      // Step 2: Create order
      Map<String, dynamic>? order = await _createPayPalOrder(
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

      // Step 3: Get approval URL
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
      if (!context.mounted) {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Màn hình đã bị đóng. Vui lòng thử lại.',
        );
      }
      
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

  /// Process Google Pay payment
  /// Returns payment result with transaction ID
  /// Shows Google Pay payment sheet for user to select card and pay
  static Future<PaymentResult> processGooglePayPayment({
    required double amount,
    required String currency,
    required String description,
    required BuildContext context,
  }) async {
    try {
      print('💳 Processing Google Pay payment: $amount $currency');
      
      // Convert VND to USD if currency is VND (Google Pay typically uses USD)
      String payCurrency = currency;
      double payAmount = amount;
      
      if (currency == 'VND') {
        // Approximate conversion: 1 USD = 24,000 VND (adjust as needed)
        payAmount = amount / 24000;
        payCurrency = 'USD';
        print('   ⚠️ Converted VND to USD: $amount VND = ${payAmount.toStringAsFixed(2)} USD');
      }

      // Create payment items
      final paymentItems = [
        PaymentItem(
          label: description,
          amount: payAmount.toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

      // Show Google Pay screen (similar to PayPal WebView)
      // This will open a dedicated screen where user can select card and pay
      print('📱 Opening Google Pay screen...');
      
      if (!context.mounted) {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Màn hình đã bị đóng. Vui lòng thử lại.',
        );
      }

      // Navigate to Google Pay screen
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => GooglePayScreen(
            amount: amount,
            currency: currency,
            description: description,
          ),
        ),
      );

      if (result == null) {
        print('❌ Google Pay payment cancelled by user');
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Bạn đã hủy giao dịch thanh toán.',
        );
      }

      final paymentResult = result['paymentData'];
      final success = result['success'] ?? false;

      if (success && paymentResult != null) {
        print('✅ Google Pay payment completed');
        print('   Payment data: ${paymentResult.toString()}');
        
        // Extract payment token from result
        // In production, you would send this to your backend to process the payment
        // For now, we'll generate a transaction ID
        String transactionId = 'GOOGLEPAY_${DateTime.now().millisecondsSinceEpoch}';
        
        // TODO: In production, send paymentResult to your backend
        // The backend should:
        // 1. Verify the payment token
        // 2. Process the payment through your payment gateway (Stripe)
        // 3. Return the actual transaction ID
        // 
        // Example:
        // final response = await http.post(
        //   Uri.parse('YOUR_BACKEND_URL/api/payments/google-pay'),
        //   headers: {'Content-Type': 'application/json'},
        //   body: json.encode({
        //     'paymentData': paymentResult.toString(),
        //     'amount': payAmount,
        //     'currency': payCurrency,
        //   }),
        // );
        // final data = json.decode(response.body);
        // transactionId = data['transactionId'];
        
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          message: 'Thanh toán Google Pay thành công',
        );
      } else {
        print('❌ Google Pay payment cancelled or failed');
        return PaymentResult(
          success: false,
          transactionId: null,
          message: result['cancelled'] == true 
              ? 'Bạn đã hủy giao dịch thanh toán.'
              : 'Thanh toán Google Pay thất bại. Vui lòng thử lại.',
        );
      }
    } catch (e) {
      print('❌ Google Pay payment error: $e');
      print('   Error type: ${e.runtimeType}');
      
      // If Google Pay is not available or error, fallback to mock for testing
      if (e.toString().contains('not available') || 
          e.toString().contains('canPay') ||
          e.toString().contains('showPaymentSelector')) {
        print('   ⚠️ Google Pay API error, using fallback mock payment');
        await Future.delayed(const Duration(seconds: 2));
        bool success = DateTime.now().millisecond % 10 != 0;
        if (success) {
          String transactionId = 'GOOGLEPAY_${DateTime.now().millisecondsSinceEpoch}';
          return PaymentResult(
            success: true,
            transactionId: transactionId,
            message: 'Thanh toán Google Pay thành công (Fallback)',
          );
        } else {
          return PaymentResult(
            success: false,
            transactionId: null,
            message: 'Thanh toán Google Pay thất bại. Vui lòng thử lại.',
          );
        }
      }
      
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Lỗi xử lý thanh toán Google Pay: $e',
      );
    }
  }

  /// Create VNPay Payment URL
  /// VNPay uses hash-based authentication
  static Future<String?> _createVNPayPaymentUrl({
    required double amount,
    required String description,
  }) async {
    try {
      print('📦 Creating VNPay payment URL...');
      print('   Amount: $amount VND');
      print('   Description: $description');
      
      if (_vnpayTmnCode.isEmpty || _vnpayHashSecret.isEmpty) {
        print('⚠️ VNPay credentials not found in .env file');
        return null;
      }

      // Generate unique order ID
      final orderId = 'VNPAY_${DateTime.now().millisecondsSinceEpoch}';
      
      // Get return URL from .env or use default
      // For mobile app, we use an HTTP URL that WebView can intercept
      // VNPay requires HTTP/HTTPS URL, not custom URL scheme
      final returnUrl = dotenv.env['VNPAY_RETURN_URL'] ?? 'https://xcinema.app/vnpay/callback';
      
      // Format create date: YYYYMMDDHHmmss
      final now = DateTime.now();
      final createDate = '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      // VNPay payment parameters (must be in alphabetical order for hash)
      // Remove empty values as VNPay requires
      final params = <String, String>{};
      
      // Add parameters (only non-empty values)
      final amountStr = (amount * 100).toInt().toString();
      if (amountStr.isNotEmpty) params['vnp_Amount'] = amountStr;
      params['vnp_Command'] = 'pay';
      if (createDate.isNotEmpty) params['vnp_CreateDate'] = createDate;
      params['vnp_CurrCode'] = 'VND';
      if ('127.0.0.1'.isNotEmpty) params['vnp_IpAddr'] = '127.0.0.1';
      params['vnp_Locale'] = 'vn'; // Use 'vn' as per your config
      if (description.isNotEmpty) params['vnp_OrderInfo'] = description;
      params['vnp_OrderType'] = 'other';
      if (returnUrl.isNotEmpty) params['vnp_ReturnUrl'] = returnUrl;
      if (_vnpayTmnCode.isNotEmpty) params['vnp_TmnCode'] = _vnpayTmnCode;
      if (orderId.isNotEmpty) params['vnp_TxnRef'] = orderId;
      params['vnp_Version'] = '2.1.0';

      // Sort parameters alphabetically (VNPay requirement)
      final sortedKeys = params.keys.toList()..sort();
      
      // Create query string WITH URL encoding for hash calculation
      // VNPay requires: hash from URL-encoded query string
      // CRITICAL: Replace %20 with + BEFORE creating hash (VNPay requirement)
      // The hash must be created from the exact same string that will be in the URL
      final hashData = sortedKeys.map((key) {
        final value = params[key]!;
        // Encode value and replace %20 with + (VNPay requires + for spaces)
        final encoded = Uri.encodeComponent(value).replaceAll('%20', '+');
        return '$key=$encoded';
      }).join('&');
      
      print('   🔍 Debug - Hash data (for signature, with + for spaces): $hashData');
      print('   🔍 Debug - Hash secret: ${_vnpayHashSecret.substring(0, _vnpayHashSecret.length > 10 ? 10 : _vnpayHashSecret.length)}... (length: ${_vnpayHashSecret.length})');
      print('   🔍 Debug - TMN Code: $_vnpayTmnCode');
      print('   🔍 Debug - Amount: ${params['vnp_Amount']}');
      print('   🔍 Debug - OrderId: ${params['vnp_TxnRef']}');
      
      // Create HMAC SHA512 hash as required by VNPay
      // Hash = HMAC SHA512(hashData, hashSecret)
      final secretKey = utf8.encode(_vnpayHashSecret);
      final dataBytes = utf8.encode(hashData);
      final hmacSha512 = Hmac(sha512, secretKey);
      final digest = hmacSha512.convert(dataBytes);
      final vnpSecureHash = digest.toString().toUpperCase();

      // Use the same query string for the actual URL
      final queryString = hashData;

      // Build payment URL
      // BaseUrl from config already includes full path: https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
      final baseUrl = _vnpayBaseUrl;
      final paymentUrl = '$baseUrl?$queryString&vnp_SecureHash=${Uri.encodeComponent(vnpSecureHash)}';
      
      print('   Secure Hash: $vnpSecureHash');
      print('   Payment URL created: $paymentUrl');

      print('   Base URL: $_vnpayBaseUrl');
      print('   TMN Code: ${_vnpayTmnCode.substring(0, _vnpayTmnCode.length > 10 ? 10 : _vnpayTmnCode.length)}...');
      print('✅ VNPay payment URL created successfully');

      return paymentUrl;
    } catch (e) {
      print('❌ Error creating VNPay payment URL: $e');
      return null;
    }
  }

  /// Process VNPay payment
  /// Returns payment result with transaction ID
  static Future<PaymentResult> processVNPayPayment({
    required double amount,
    required String description,
    required BuildContext context,
  }) async {
    try {
      print('💳 Processing VNPay payment: $amount VND');
      
      // Check if credentials are available
      if (_vnpayTmnCode.isEmpty || _vnpayHashSecret.isEmpty) {
        print('⚠️ VNPay credentials not configured. Using mock payment.');
        // Fallback to mock payment for testing
        await Future.delayed(const Duration(seconds: 1));
        final paymentUrl = 'https://www.vnpay.vn/payment/mock?amount=$amount&description=${Uri.encodeComponent(description)}';
        String? transactionId = await _showVNPayWebView(
          context: context,
          paymentUrl: paymentUrl,
          amount: amount,
          description: description,
        );
        
        if (transactionId != null) {
          return PaymentResult(
            success: true,
            transactionId: transactionId,
            message: 'Thanh toán VNPay thành công (Mock)',
          );
        } else {
          return PaymentResult(
            success: false,
            transactionId: null,
            message: 'Thanh toán VNPay đã bị hủy hoặc thất bại.',
          );
        }
      }

      // Step 1: Create payment URL
      String? paymentUrl = await _createVNPayPaymentUrl(
        amount: amount,
        description: description,
      );

      if (paymentUrl == null) {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Không thể tạo URL thanh toán VNPay. Vui lòng thử lại.',
        );
      }

      // Step 2: Open VNPay checkout in WebView
      if (!context.mounted) {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Màn hình đã bị đóng. Vui lòng thử lại.',
        );
      }
      
      String? transactionId = await _showVNPayWebView(
        context: context,
        paymentUrl: paymentUrl,
        amount: amount,
        description: description,
      );

      if (transactionId != null) {
        print('✅ VNPay payment successful: $transactionId');
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          message: 'Thanh toán VNPay thành công',
        );
      } else {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Thanh toán VNPay đã bị hủy hoặc thất bại.',
        );
      }
    } catch (e) {
      print('❌ VNPay payment error: $e');
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Lỗi xử lý thanh toán VNPay: $e',
      );
    }
  }

  /// Show VNPay payment in WebView
  static Future<String?> _showVNPayWebView({
    required BuildContext context,
    required String paymentUrl,
    required double amount,
    required String description,
  }) async {
    final Completer<String?> completer = Completer<String?>();
    bool paymentCompleted = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(false)
          ..setBackgroundColor(Colors.white);

        controller.setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (WebResourceError error) {
              print('❌ WebView resource error: ${error.description}');
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (!completer.isCompleted) completer.complete(null);
            },
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url;
              print('🌐 VNPay WebView navigation: $url');

              // Detect success or cancel URLs from VNPay callback
              // VNPay will redirect to return URL with vnp_ResponseCode parameter
              final uri = Uri.parse(url);
              final responseCode = uri.queryParameters['vnp_ResponseCode'];
              
              // Check for callback URL pattern or vnp_ResponseCode in URL
              // VNPay will redirect to return URL with vnp_ResponseCode parameter
              final isCallbackUrl = url.contains('vnpay/callback') ||
                                    url.contains('xcinema.app/vnpay') ||
                                    (responseCode != null);
              
              if (isCallbackUrl) {
                // Check for success (ResponseCode = 00)
                if (responseCode == '00') {
                  if (!paymentCompleted) {
                    paymentCompleted = true;
                    print('✅ VNPay payment success detected');
                    // Extract transaction ID from URL
                    final transactionId = uri.queryParameters['vnp_TxnRef'] ?? 
                                         uri.queryParameters['vnp_TransactionNo'] ??
                                         'VNPAY_${DateTime.now().millisecondsSinceEpoch}';
                    print('   Transaction ID: $transactionId');
                    print('   Response Code: $responseCode');
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    if (!completer.isCompleted) completer.complete(transactionId);
                  }
                  return NavigationDecision.prevent;
                } else if (responseCode != null) {
                  // Payment failed or cancelled (ResponseCode != 00)
                  if (!paymentCompleted) {
                    print('❌ VNPay payment failed. ResponseCode: $responseCode');
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    if (!completer.isCompleted) completer.complete(null);
                  }
                  return NavigationDecision.prevent;
                } else if (url.contains('cancel') || url.contains('payment_cancel')) {
                  // User cancelled
                  if (!paymentCompleted) {
                    print('❌ VNPay payment cancelled by user');
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    if (!completer.isCompleted) completer.complete(null);
                  }
                  return NavigationDecision.prevent;
                }
              }
              return NavigationDecision.navigate;
            },
          ),
        );

        // Check if paymentUrl is a real VNPay URL or mock URL
        final isRealUrl = paymentUrl.startsWith('https://') && 
                          (paymentUrl.contains('vnpay.vn') || 
                           paymentUrl.contains('vnpayment.vn') ||
                           paymentUrl.contains('sandbox.vnpayment.vn'));
        
        if (isRealUrl) {
          // Load real VNPay payment URL
          print('🔐 Loading VNPay payment page from API: $paymentUrl');
          controller.loadRequest(Uri.parse(paymentUrl));
        } else {
          // Create a mock VNPay payment page for testing
          final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>VNPay - Thanh toán</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      margin: 0;
      padding: 20px;
      background: linear-gradient(135deg, #EE2D24 0%, #FF4D45 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .container {
      background: white;
      border-radius: 16px;
      padding: 32px;
      max-width: 400px;
      width: 100%;
      box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    }
    .logo {
      text-align: center;
      margin-bottom: 32px;
    }
    .logo h1 {
      color: #EE2D24;
      margin: 0;
      font-size: 28px;
    }
    .amount {
      text-align: center;
      margin-bottom: 32px;
    }
    .amount-label {
      color: #666;
      font-size: 14px;
      margin-bottom: 8px;
    }
    .amount-value {
      color: #EE2D24;
      font-size: 36px;
      font-weight: bold;
    }
    .description {
      color: #333;
      font-size: 16px;
      margin-bottom: 32px;
      text-align: center;
    }
    .button-group {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    button {
      padding: 16px;
      border: none;
      border-radius: 8px;
      font-size: 16px;
      font-weight: bold;
      cursor: pointer;
      transition: all 0.3s;
    }
    .btn-success {
      background: #EE2D24;
      color: white;
    }
    .btn-success:hover {
      background: #D01E15;
    }
    .btn-cancel {
      background: #f5f5f5;
      color: #666;
    }
    .btn-cancel:hover {
      background: #e0e0e0;
    }
    .mock-note {
      margin-top: 24px;
      padding: 12px;
      background: #FFEBEE;
      border-radius: 8px;
      font-size: 12px;
      color: #C62828;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <h1>🔴 VNPay</h1>
    </div>
    <div class="amount">
      <div class="amount-label">Số tiền thanh toán</div>
      <div class="amount-value">${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫</div>
    </div>
    <div class="description">$description</div>
    <div class="button-group">
      <button class="btn-success" onclick="handleSuccess()">Xác nhận thanh toán</button>
      <button class="btn-cancel" onclick="handleCancel()">Hủy</button>
    </div>
    <div class="mock-note">
      ⚠️ Đây là trang thanh toán mô phỏng cho mục đích demo
    </div>
  </div>
  <script>
    function handleSuccess() {
      window.location.href = 'https://xcinema.app/vnpay/success?transaction_id=VNPAY_' + Date.now();
    }
    function handleCancel() {
      window.location.href = 'https://xcinema.app/vnpay/cancel';
    }
  </script>
</body>
</html>
          ''';
          print('🔐 Loading VNPay mock payment page');
          controller.loadHtmlString(htmlContent);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'VNPay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEE2D24),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                          if (!completer.isCompleted) completer.complete(null);
                        },
                      ),
                    ],
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

  /// Process ZaloPay payment
  /// Returns payment result with transaction ID
  static Future<PaymentResult> processZaloPayPayment({
    required double amount,
    required String description,
    required BuildContext context,
  }) async {
    try {
      print('💳 Processing ZaloPay payment: $amount VND');
      
      // In production, you would:
      // 1. Create order on ZaloPay API
      // 2. Get payment URL
      // 3. Open ZaloPay app or webview
      // 4. Handle callback and verify payment
      
      // For demo/testing, we'll simulate the payment with WebView
      // Similar to PayPal flow
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate creating payment URL
      final paymentUrl = 'https://zalopay.vn/payment/mock?amount=$amount&description=${Uri.encodeComponent(description)}';
      
      // Show ZaloPay WebView
      String? transactionId = await _showZaloPayWebView(
        context: context,
        paymentUrl: paymentUrl,
        amount: amount,
        description: description,
      );
      
      if (transactionId != null) {
        print('✅ ZaloPay payment successful: $transactionId');
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          message: 'Thanh toán ZaloPay thành công',
        );
      } else {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Thanh toán ZaloPay đã bị hủy hoặc thất bại.',
        );
      }
    } catch (e) {
      print('❌ ZaloPay payment error: $e');
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Lỗi xử lý thanh toán ZaloPay: $e',
      );
    }
  }

  /// Show ZaloPay payment in WebView
  static Future<String?> _showZaloPayWebView({
    required BuildContext context,
    required String paymentUrl,
    required double amount,
    required String description,
  }) async {
    final Completer<String?> completer = Completer<String?>();
    bool paymentCompleted = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(false)
          ..setBackgroundColor(Colors.white);

        controller.setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (WebResourceError error) {
              print('❌ WebView resource error: ${error.description}');
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (!completer.isCompleted) completer.complete(null);
            },
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url;
              print('🌐 ZaloPay WebView navigation: $url');

              // Detect success or cancel URLs
              if (url.contains('success') || url.contains('payment_success')) {
                if (!paymentCompleted) {
                  paymentCompleted = true;
                  print('✅ ZaloPay payment success detected');
                  final transactionId = 'ZALOPAY_${DateTime.now().millisecondsSinceEpoch}';
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (!completer.isCompleted) completer.complete(transactionId);
                }
                return NavigationDecision.prevent;
              } else if (url.contains('cancel') || url.contains('payment_cancel')) {
                if (!paymentCompleted) {
                  print('❌ ZaloPay payment cancelled by user');
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (!completer.isCompleted) completer.complete(null);
                }
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );

        // Create a mock ZaloPay payment page
        final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ZaloPay - Thanh toán</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      margin: 0;
      padding: 20px;
      background: linear-gradient(135deg, #0068FF 0%, #0052CC 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .container {
      background: white;
      border-radius: 16px;
      padding: 32px;
      max-width: 400px;
      width: 100%;
      box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    }
    .logo {
      text-align: center;
      margin-bottom: 32px;
    }
    .logo h1 {
      color: #0068FF;
      margin: 0;
      font-size: 28px;
    }
    .amount {
      text-align: center;
      margin-bottom: 32px;
    }
    .amount-label {
      color: #666;
      font-size: 14px;
      margin-bottom: 8px;
    }
    .amount-value {
      color: #0068FF;
      font-size: 36px;
      font-weight: bold;
    }
    .description {
      color: #333;
      font-size: 16px;
      margin-bottom: 32px;
      text-align: center;
    }
    .button-group {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    button {
      padding: 16px;
      border: none;
      border-radius: 8px;
      font-size: 16px;
      font-weight: bold;
      cursor: pointer;
      transition: all 0.3s;
    }
    .btn-success {
      background: #0068FF;
      color: white;
    }
    .btn-success:hover {
      background: #0052CC;
    }
    .btn-cancel {
      background: #f5f5f5;
      color: #666;
    }
    .btn-cancel:hover {
      background: #e0e0e0;
    }
    .mock-note {
      margin-top: 24px;
      padding: 12px;
      background: #E3F2FD;
      border-radius: 8px;
      font-size: 12px;
      color: #1976D2;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <h1>💙 ZaloPay</h1>
    </div>
    <div class="amount">
      <div class="amount-label">Số tiền thanh toán</div>
      <div class="amount-value">${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫</div>
    </div>
    <div class="description">$description</div>
    <div class="button-group">
      <button class="btn-success" onclick="handleSuccess()">Xác nhận thanh toán</button>
      <button class="btn-cancel" onclick="handleCancel()">Hủy</button>
    </div>
    <div class="mock-note">
      ⚠️ Đây là trang thanh toán mô phỏng cho mục đích demo
    </div>
  </div>
  <script>
    function handleSuccess() {
      window.location.href = 'https://zalopay.vn/payment/success?transaction_id=ZALOPAY_' + Date.now();
    }
    function handleCancel() {
      window.location.href = 'https://zalopay.vn/payment/cancel';
    }
  </script>
</body>
</html>
        ''';

        print('🔐 Loading ZaloPay payment page');
        controller.loadHtmlString(htmlContent);

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'ZaloPay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0068FF),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                          if (!completer.isCompleted) completer.complete(null);
                        },
                      ),
                    ],
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

  /// Process payment based on selected method
  static Future<PaymentResult> processPayment({
    required PaymentMethod method,
    required double amount,
    required String description,
    required BuildContext context,
    String currency = 'VND',
  }) async {
    switch (method) {
      case PaymentMethod.paypal:
        return await processPayPalPayment(
          amount: amount,
          currency: currency,
          description: description,
          context: context,
        );
      case PaymentMethod.vnpay:
        return await processVNPayPayment(
          amount: amount,
          description: description,
          context: context,
        );
      case PaymentMethod.zaloPay:
        return await processZaloPayPayment(
          amount: amount,
          description: description,
          context: context,
        );
    }
  }
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String message;

  PaymentResult({
    required this.success,
    this.transactionId,
    required this.message,
  });
}

