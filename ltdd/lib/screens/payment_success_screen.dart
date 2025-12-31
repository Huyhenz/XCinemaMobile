// File: lib/screens/payment_success_screen.dart
// Screen hiển thị khi thanh toán PayPal thành công

import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String? transactionId;
  final String? message;
  final bool? emailSent;
  final String? userEmail;
  final String? emailError;

  const PaymentSuccessScreen({
    super.key,
    this.transactionId,
    this.message,
    this.emailSent,
    this.userEmail,
    this.emailError,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Success Title
                const Text(
                  'Thanh toán thành công!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Success Message
                Text(
                  message ?? 'Giao dịch của bạn đã được xử lý thành công.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Transaction ID (if available)
                if (transactionId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mã giao dịch:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          transactionId!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Email Status
                if (emailSent != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: emailSent == true 
                          ? const Color(0xFF4CAF50).withOpacity(0.1)
                          : const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: emailSent == true 
                            ? const Color(0xFF4CAF50).withOpacity(0.5)
                            : const Color(0xFFFF9800).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          emailSent == true 
                              ? Icons.email
                              : Icons.warning_amber_rounded,
                          color: emailSent == true 
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emailSent == true 
                                    ? 'Email xác nhận đã được gửi'
                                    : 'Email xác nhận chưa được gửi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: emailSent == true 
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFF9800),
                                ),
                              ),
                              if (emailSent == true && userEmail != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Đã gửi đến: $userEmail',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              if (emailSent == false) ...[
                                const SizedBox(height: 4),
                                Text(
                                  emailError ?? 'Vui lòng kiểm tra cấu hình SMTP trong file .env',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '💡 Lưu ý: Vé đã được đặt thành công và có trong lịch sử đặt vé.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to home and clear navigation stack
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Về Trang Chủ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // View Booking Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to profile/bookings
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      // You can add navigation to bookings screen here
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE50914), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Xem Đặt Vé',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE50914),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

