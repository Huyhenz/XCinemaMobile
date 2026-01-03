// File: lib/utils/error_handler.dart
// Centralized error handling

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dialog_helper.dart';

class ErrorHandler {
  // Get user-friendly error message
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error.code);
    }
    
    // Handle other Firebase exceptions
    if (error.toString().contains('network') || error.toString().contains('internet')) {
      return 'Không có kết nối internet. Vui lòng kiểm tra lại.';
    }
    
    // Generic error
    return error.toString().replaceAll('Exception:', '').trim();
  }

  // Get Firebase Auth error messages in Vietnamese
  static String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email không tồn tại';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng sử dụng ít nhất 6 ký tự';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      case 'operation-not-allowed':
        return 'Thao tác không được phép';
      case 'requires-recent-login':
        return 'Vui lòng đăng nhập lại để thực hiện thao tác này';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet';
      default:
        return 'Có lỗi xảy ra: $code';
    }
  }

  // Show error dialog
  static Future<void> showError(BuildContext context, dynamic error) {
    return DialogHelper.showError(context, getErrorMessage(error));
  }

  // Show success dialog
  static Future<void> showSuccess(BuildContext context, String message) {
    return DialogHelper.showSuccess(context, message);
  }

  // Show info dialog
  static Future<void> showInfo(BuildContext context, String message) {
    return DialogHelper.showInfo(context, message);
  }
}

