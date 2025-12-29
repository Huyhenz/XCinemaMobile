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
import '../screens/payment_success_screen.dart';
import '../screens/payment_failure_screen.dart';

enum PaymentMethod {
  paypal,
  googlePay,
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
  static Future<PaymentResult> processGooglePayPayment({
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      print('💳 Processing Google Pay payment: $amount $currency');
      
      // In production, you would:
      // 1. Check if Google Pay is available
      // 2. Load payment data request
      // 3. Show Google Pay sheet
      // 4. Process payment token on your backend
      // 5. Verify and complete payment
      
      // For demo/testing, we'll simulate the payment
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate success (90% success rate for demo)
      bool success = DateTime.now().millisecond % 10 != 0;
      
      if (success) {
        String transactionId = 'GOOGLEPAY_${DateTime.now().millisecondsSinceEpoch}';
        print('✅ Google Pay payment successful: $transactionId');
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          message: 'Thanh toán Google Pay thành công',
        );
      } else {
        print('❌ Google Pay payment failed');
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Thanh toán Google Pay thất bại. Vui lòng thử lại.',
        );
      }
    } catch (e) {
      print('❌ Google Pay payment error: $e');
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Lỗi xử lý thanh toán Google Pay: $e',
      );
    }
  }

  /// Process ZaloPay payment
  /// Returns payment result with transaction ID
  static Future<PaymentResult> processZaloPayPayment({
    required double amount,
    required String description,
  }) async {
    try {
      print('💳 Processing ZaloPay payment: $amount VND');
      
      // In production, you would:
      // 1. Create order on ZaloPay API
      // 2. Get payment URL
      // 3. Open ZaloPay app or webview
      // 4. Handle callback and verify payment
      
      // For demo/testing, we'll simulate the payment
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate success (90% success rate for demo)
      bool success = DateTime.now().millisecond % 10 != 0;
      
      if (success) {
        String transactionId = 'ZALOPAY_${DateTime.now().millisecondsSinceEpoch}';
        print('✅ ZaloPay payment successful: $transactionId');
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          message: 'Thanh toán ZaloPay thành công',
        );
      } else {
        print('❌ ZaloPay payment failed');
        return PaymentResult(
          success: false,
          transactionId: null,
          message: 'Thanh toán ZaloPay thất bại. Vui lòng thử lại.',
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
      case PaymentMethod.googlePay:
        return await processGooglePayPayment(
          amount: amount,
          currency: currency,
          description: description,
        );
      case PaymentMethod.zaloPay:
        return await processZaloPayPayment(
          amount: amount,
          description: description,
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

