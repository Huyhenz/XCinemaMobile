// File: lib/screens/redeem_voucher_screen.dart
// Màn hình đổi voucher bằng điểm

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/voucher.dart';
import '../models/user.dart';
import '../services/points_service.dart';
import '../services/database_services.dart';
import '../utils/dialog_helper.dart';

class RedeemVoucherScreen extends StatefulWidget {
  const RedeemVoucherScreen({super.key});

  @override
  State<RedeemVoucherScreen> createState() => _RedeemVoucherScreenState();
}

class _RedeemVoucherScreenState extends State<RedeemVoucherScreen> {
  final PointsService _pointsService = PointsService();
  final DatabaseService _dbService = DatabaseService();
  
  List<VoucherModel> _vouchers = [];
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        _user = await _dbService.getUser(userId);
      }
      _vouchers = await _pointsService.getRedeemableVouchers();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _redeemVoucher(VoucherModel voucher) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_user == null || _user!.points < (voucher.points ?? 0)) {
      if (mounted) {
        await DialogHelper.showError(context, 'Không đủ điểm để đổi voucher. Cần ${voucher.points} điểm, bạn có ${_user?.points ?? 0} điểm');
      }
      return;
    }

    // Xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Xác nhận đổi voucher',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc muốn đổi voucher "${voucher.id}" với ${voucher.points} điểm?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
            ),
            child: const Text('Đổi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _pointsService.redeemVoucherWithPoints(userId, voucher.id);
      if (mounted) {
        await DialogHelper.showSuccess(context, '✅ Đã đổi voucher thành công!');
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        await DialogHelper.showError(context, 'Lỗi: $e');
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
          'Đổi Voucher',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            )
          : _user == null
              ? const Center(
                  child: Text(
                    'Vui lòng đăng nhập',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    // Points display
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE50914), Color(0xFFB20710)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stars, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Text(
                            '${_user!.points} điểm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Vouchers list
                    Expanded(
                      child: _vouchers.isEmpty
                          ? const Center(
                              child: Text(
                                'Không có voucher nào để đổi',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _vouchers.length,
                              itemBuilder: (context, index) {
                                final voucher = _vouchers[index];
                                final canRedeem = _user!.points >= (voucher.points ?? 0);
                                return _buildVoucherCard(voucher, canRedeem);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildVoucherCard(VoucherModel voucher, bool canRedeem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canRedeem ? const Color(0xFFE50914) : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      voucher.type == 'percent'
                          ? 'Giảm ${voucher.discount}%'
                          : 'Giảm ${voucher.discount.toStringAsFixed(0)}đ',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Color(0xFFE50914), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${voucher.points} điểm',
                      style: const TextStyle(
                        color: Color(0xFFE50914),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: canRedeem
                ? () => _redeemVoucher(voucher)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
            ),
            child: Text(
              canRedeem ? 'Đổi Voucher' : 'Không đủ điểm',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

