// File: lib/widgets/auth_guard.dart
// Helper widget to check authentication and redirect to login if needed

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';

class AuthGuard {
  /// Check if user is authenticated, if not show login dialog/screen
  /// [returnPath] là đường dẫn quay lại sau khi đăng nhập (ví dụ: 'booking:showtimeId')
  static Future<bool> requireAuth(BuildContext context, {String? returnPath}) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // Show login required dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.login, color: Color(0xFFE50914)),
              SizedBox(width: 12),
              Text(
                'Đăng Nhập Bắt Buộc',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'Bạn cần đăng nhập để tiếp tục đặt vé. Vui lòng đăng nhập hoặc đăng ký tài khoản.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
              ),
              child: const Text('Đăng Nhập'),
            ),
          ],
        ),
      );
      
      if (result == true) {
        // Navigate to login screen với return path
        final loginResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              isLoginMode: true,
              returnPath: returnPath,
            ),
          ),
        );
        
        // Return true if login successful
        return FirebaseAuth.instance.currentUser != null;
      }
      
      return false;
    }
    
    return true;
  }
}

