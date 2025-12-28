// File: lib/screens/all_vouchers_screen.dart
// Màn hình xem tất cả voucher có thể lấy được

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/voucher.dart';
import '../services/database_services.dart';
import '../models/user.dart';
import 'redeem_voucher_screen.dart';

class AllVouchersScreen extends StatefulWidget {
  const AllVouchersScreen({super.key});

  @override
  State<AllVouchersScreen> createState() => _AllVouchersScreenState();
}

class _AllVouchersScreenState extends State<AllVouchersScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  List<VoucherModel> _allVouchers = [];
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
      final allVouchers = await _dbService.getAllVouchers();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Filter active vouchers that haven't expired
      setState(() {
        _allVouchers = allVouchers.where((voucher) {
          return voucher.isActive && voucher.expiryDate > now;
        }).toList();
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getVoucherColor(VoucherModel voucher) {
    if (voucher.points != null) {
      return const Color(0xFFE50914);
    } else {
      return const Color(0xFF4CAF50);
    }
  }

  IconData _getVoucherIcon(VoucherModel voucher) {
    if (voucher.points != null) {
      return Icons.stars;
    } else {
      return Icons.card_giftcard;
    }
  }

  void _navigateToAction(VoucherModel voucher) {
    if (voucher.points != null) {
      // Navigate to redeem voucher screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RedeemVoucherScreen(),
        ),
      );
    } else {
      // Show dialog with options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Cách Nhận Voucher',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Voucher này có thể nhận được qua:\n• Thực hiện nhiệm vụ\n• Chơi minigame',
            style: TextStyle(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Tất Cả Voucher',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            )
          : _allVouchers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có voucher nào',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // User points display
                    if (_user != null)
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
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
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _allVouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = _allVouchers[index];
                          final voucherColor = _getVoucherColor(voucher);
                          final canRedeem = _user != null && 
                              voucher.points != null && 
                              _user!.points >= voucher.points!;
                          
                          return _buildVoucherCard(voucher, voucherColor, canRedeem);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildVoucherCard(
    VoucherModel voucher,
    Color voucherColor,
    bool canRedeem,
  ) {
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(voucher.expiryDate);
    final dateFormat = DateFormat('dd/MM/yyyy', 'vi_VN');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: canRedeem ? voucherColor : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToAction(voucher),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Voucher icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: voucherColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getVoucherIcon(voucher),
                        color: voucherColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          const SizedBox(height: 4),
                          Text(
                            voucher.type == 'percent'
                                ? 'Giảm ${voucher.discount.toStringAsFixed(0)}%'
                                : 'Giảm ${voucher.discount.toStringAsFixed(0)}đ',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Source badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: voucherColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        voucher.points != null ? '${voucher.points} điểm' : 'Miễn phí',
                        style: TextStyle(
                          color: voucherColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Expiry date
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hết hạn: ${dateFormat.format(expiryDate)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _navigateToAction(voucher),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: voucherColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          voucher.points != null ? Icons.swap_horiz : Icons.card_giftcard,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          voucher.points != null
                              ? (canRedeem ? 'Đổi Ngay' : 'Không Đủ Điểm')
                              : 'Xem Cách Nhận',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

