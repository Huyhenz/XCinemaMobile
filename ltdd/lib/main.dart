import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ltdd/widgets/main_wrapper.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/cinema_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    // Try loading from assets first (for mobile)
    await dotenv.load(fileName: ".env");
    print('✅ Loaded .env file successfully');
    
    // Check PayPal config
    final clientId = dotenv.env['PAYPAL_CLIENT_ID'] ?? '';
    if (clientId.isNotEmpty) {
      print('📝 PayPal Client ID: ${clientId.substring(0, clientId.length > 10 ? 10 : clientId.length)}...');
    } else {
      print('⚠️ PayPal Client ID not found in .env');
    }
    
    // Check VNPay config
    final vnpayTmnCode = dotenv.env['VNPAY_TMN_CODE'] ?? '';
    final vnpayHashSecret = dotenv.env['VNPAY_HASH_SECRET'] ?? '';
    if (vnpayTmnCode.isNotEmpty && vnpayHashSecret.isNotEmpty) {
      print('✅ VNPay credentials found in .env');
      print('📝 VNPay TMN Code: ${vnpayTmnCode.substring(0, vnpayTmnCode.length > 10 ? 10 : vnpayTmnCode.length)}...');
      print('📝 VNPay Mode: ${dotenv.env['VNPAY_MODE'] ?? 'sandbox'}');
    } else {
      print('⚠️ VNPay credentials not found in .env (VNPay payment will use mock)');
      print('💡 To enable real VNPay payment, add VNPAY_TMN_CODE, VNPAY_HASH_SECRET to .env file');
    }
    
    // Check SMTP config
    final smtpUsername = dotenv.env['SMTP_USERNAME'] ?? '';
    final smtpPassword = dotenv.env['SMTP_PASSWORD'] ?? '';
    if (smtpUsername.isNotEmpty && smtpPassword.isNotEmpty) {
      print('✅ SMTP credentials found in .env');
      print('📧 SMTP Host: ${dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com'}');
    } else {
      print('⚠️ SMTP credentials not found in .env (email confirmation will be skipped)');
      print('💡 To enable email confirmation, add SMTP config to .env file');
    }
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
    print('💡 Tip: Make sure .env file exists and is added to pubspec.yaml assets');
    // App will continue but PayPal payment and email will use fallback modes
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize locale data for Vietnamese
  await initializeDateFormatting('vi_VN', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinema Ticket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE50914),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE50914),
          secondary: Color(0xFFB20710),
          surface: Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          selectedItemColor: Color(0xFFE50914),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const AuthChecker(),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Sử dụng userChanges để lắng nghe cả các thay đổi như reload user (verification)
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F0F),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE50914),
              ),
            ),
          );
        }

        // Cho phép vào app không cần login - luôn hiển thị MainWrapper với bottom navigation
        // Chỉ yêu cầu login khi đặt vé
        return const MainWrapper();
      },
    );
  }
}