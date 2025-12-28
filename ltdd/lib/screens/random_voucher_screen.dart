// File: lib/screens/random_voucher_screen.dart
// Màn hình nhận voucher ngẫu nhiên

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/voucher.dart';
import '../services/points_service.dart';

class RandomVoucherScreen extends StatefulWidget {
  const RandomVoucherScreen({super.key});

  @override
  State<RandomVoucherScreen> createState() => _RandomVoucherScreenState();
}

class _RandomVoucherScreenState extends State<RandomVoucherScreen> {
  final PointsService _pointsService = PointsService();
  VoucherModel? _voucher;
  bool _isLoading = false;
  bool _hasReceived = false;

  Future<void> _getRandomVoucher() async {
    setState(() {
      _isLoading = true;
      _voucher = null;
      _hasReceived = false;
    });

    try {
      final voucher = await _pointsService.getRandomFreeVoucher();
      if (voucher != null) {
        setState(() {
          _voucher = voucher;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hiện không có voucher miễn phí nào'),
              backgroundColor: Color(0xFFE50914),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _receiveVoucher() async {
    if (_voucher == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập'),
            backgroundColor: Color(0xFFE50914),
          ),
        );
      }
      return;
    }

    try {
      await _pointsService.addRandomVoucherToUser(userId, _voucher!.id);
      setState(() => _hasReceived = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã nhận voucher thành công!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Nhận Voucher Ngẫu Nhiên',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gift box icon
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFFB20710)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE50914).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.card_giftcard,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Nhận Voucher Miễn Phí',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút bên dưới để nhận voucher ngẫu nhiên',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Voucher display
            if (_voucher != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE50914),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _voucher!.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _voucher!.type == 'percent'
                          ? 'Giảm ${_voucher!.discount}%'
                          : 'Giảm ${_voucher!.discount.toStringAsFixed(0)}đ',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18,
                      ),
                    ),
                    if (_hasReceived) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                            SizedBox(width: 8),
                            Text(
                              'Đã nhận voucher',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (_voucher == null || !_hasReceived)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _voucher == null
                                ? _getRandomVoucher
                                : _receiveVoucher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE50914),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _voucher == null
                                    ? 'Nhận Voucher Ngẫu Nhiên'
                                    : 'Xác Nhận Nhận Voucher',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  if (_voucher != null && !_hasReceived) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _getRandomVoucher,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE50914),
                          side: const BorderSide(color: Color(0xFFE50914)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Thử Lại',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

