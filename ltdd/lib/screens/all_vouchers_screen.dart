// File: lib/screens/all_vouchers_screen.dart
// Màn hình xem tất cả voucher có thể lấy được

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/voucher.dart';
import '../services/database_services.dart';
import '../models/user.dart';
import '../services/points_service.dart';
import '../utils/dialog_helper.dart';
import 'redeem_voucher_screen.dart';
import 'voucher_tasks_screen.dart';

class AllVouchersScreen extends StatefulWidget {
  const AllVouchersScreen({super.key});

  @override
  State<AllVouchersScreen> createState() => _AllVouchersScreenState();
}

class _AllVouchersScreenState extends State<AllVouchersScreen> {
  final DatabaseService _dbService = DatabaseService();
  final PointsService _pointsService = PointsService();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  List<VoucherModel> _allVouchers = [];
  UserModel? _user;
  bool _isLoading = true;
  Map<String, bool> _taskCompletionStatus = {}; // Track task completion

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
        await _checkTaskCompletions(userId);
      }
      final allVouchers = await _dbService.getAllVouchers();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Filter active vouchers that haven't expired and update unlock status
      setState(() {
        _allVouchers = allVouchers.where((voucher) {
          return voucher.isActive && voucher.expiryDate > now;
        }).map((voucher) {
          // Update unlock status for task vouchers
          if (voucher.voucherType == 'task' && voucher.requiredTaskId != null) {
            final isTaskCompleted = _taskCompletionStatus[voucher.requiredTaskId!] ?? false;
            return VoucherModel(
              id: voucher.id,
              discount: voucher.discount,
              type: voucher.type,
              expiryDate: voucher.expiryDate,
              isActive: voucher.isActive,
              points: voucher.points,
              voucherType: voucher.voucherType,
              requiredTaskId: voucher.requiredTaskId,
              isUnlocked: isTaskCompleted,
            );
          }
          return voucher;
        }).toList();
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Check task completion status for task vouchers
  Future<void> _checkTaskCompletions(String userId) async {
    try {
      // Check completed tasks from user's task history
      final snapshot = await _dbRef.child('users/$userId/completedTasks').get();
      if (snapshot.exists) {
        final completedTasks = snapshot.value;
        if (completedTasks is Map) {
          setState(() {
            _taskCompletionStatus = Map<String, bool>.from(
              completedTasks.map((key, value) => MapEntry(key.toString(), true)),
            );
          });
        }
      }
    } catch (e) {
      print('Error checking task completions: $e');
    }
  }

  Color _getVoucherColor(VoucherModel voucher) {
    switch (voucher.voucherType) {
      case 'free':
        return const Color(0xFF4CAF50); // Xanh lá - Free
      case 'task':
        return voucher.isUnlocked 
            ? const Color(0xFF2196F3) // Xanh dương - Đã unlock
            : Colors.grey[700]!; // Xám - Chưa unlock
      case 'points':
        return const Color(0xFFE50914); // Đỏ - Cần điểm
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _getVoucherIcon(VoucherModel voucher) {
    switch (voucher.voucherType) {
      case 'free':
        return Icons.card_giftcard;
      case 'task':
        return voucher.isUnlocked ? Icons.lock_open : Icons.lock;
      case 'points':
        return Icons.stars;
      default:
        return Icons.card_giftcard;
    }
  }

  String _getVoucherTypeLabel(VoucherModel voucher) {
    switch (voucher.voucherType) {
      case 'free':
        return 'Miễn phí';
      case 'task':
        return voucher.isUnlocked ? 'Đã mở khóa' : 'Cần làm nhiệm vụ';
      case 'points':
        return voucher.points != null ? '${voucher.points} điểm' : 'Cần điểm';
      default:
        return 'Miễn phí';
    }
  }

  Future<void> _claimFreeVoucher(VoucherModel voucher) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Add voucher to user's vouchers với source tương ứng
      String source = 'direct';
      if (voucher.voucherType == 'free') {
        source = 'free';
      } else if (voucher.voucherType == 'task') {
        source = 'task';
      }
      
      await _pointsService.addUserVoucher(userId, voucher.id, source: source);
      
      if (mounted) {
        await DialogHelper.showSuccess(context, 'Đã nhận voucher ${voucher.id}!');
        // Reload data to refresh UI
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        await DialogHelper.showError(context, 'Lỗi khi nhận voucher: $e');
      }
    }
  }

  void _navigateToAction(VoucherModel voucher) {
    switch (voucher.voucherType) {
      case 'free':
        // Nhận voucher free ngay
        _claimFreeVoucher(voucher);
        break;
      case 'task':
        if (voucher.isUnlocked) {
          // Đã unlock, có thể nhận
          _claimFreeVoucher(voucher);
        } else {
          // Chưa unlock, điều hướng đến màn hình nhiệm vụ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VoucherTasksScreen(),
            ),
          );
        }
        break;
      case 'points':
        // Điều hướng đến màn hình đổi điểm
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RedeemVoucherScreen(),
          ),
        );
        break;
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
                          
                          // Check if can redeem based on voucher type
                          bool canRedeem = false;
                          if (voucher.voucherType == 'free') {
                            canRedeem = true;
                          } else if (voucher.voucherType == 'task') {
                            canRedeem = voucher.isUnlocked;
                          } else if (voucher.voucherType == 'points') {
                            canRedeem = _user != null && 
                                voucher.points != null && 
                                _user!.points >= voucher.points!;
                          }
                          
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
                        _getVoucherTypeLabel(voucher),
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
                // Info message for task vouchers
                if (voucher.voucherType == 'task' && !voucher.isUnlocked)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hoàn thành nhiệm vụ để mở khóa voucher này',
                            style: TextStyle(
                              color: Colors.orange[300],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Points info for points vouchers
                if (voucher.voucherType == 'points' && !canRedeem && _user != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bạn có ${_user!.points} điểm, cần ${voucher.points} điểm',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _navigateToAction(voucher),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canRedeem ? voucherColor : Colors.grey[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          voucher.voucherType == 'free' 
                              ? Icons.card_giftcard
                              : voucher.voucherType == 'task'
                                  ? (voucher.isUnlocked ? Icons.card_giftcard : Icons.task_alt)
                                  : Icons.swap_horiz,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          voucher.voucherType == 'free'
                              ? 'Nhận Ngay'
                              : voucher.voucherType == 'task'
                                  ? (voucher.isUnlocked ? 'Nhận Ngay' : 'Làm Nhiệm Vụ')
                                  : (canRedeem ? 'Đổi Ngay' : 'Không Đủ Điểm'),
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

