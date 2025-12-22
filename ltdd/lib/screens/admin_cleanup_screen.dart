// File: lib/screens/admin_cleanup_screen.dart
// Màn hình để admin xóa và tạo lại data

import 'package:flutter/material.dart';
import '../utils/firebase_cleanup.dart';
import '../utils/complete_database_fix.dart';

class AdminCleanupScreen extends StatefulWidget {
  const AdminCleanupScreen({super.key});

  @override
  State<AdminCleanupScreen> createState() => _AdminCleanupScreenState();
}

class _AdminCleanupScreenState extends State<AdminCleanupScreen> {
  bool _isProcessing = false;
  String _status = 'Sẵn sàng xóa và tạo lại data';

  Future<void> _deleteAllData() async {
    // Confirm dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('CẢNH BÁO!', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          'Bạn có CHẮC CHẮN muốn XÓA HẾT dữ liệu?\n\n'
              '⚠️ Sẽ xóa:\n'
              '- Tất cả movies\n'
              '- Tất cả theaters\n'
              '- Tất cả showtimes\n'
              '- Tất cả bookings\n'
              '- Tất cả payments\n'
              '- Tất cả notifications\n'
              '- Tất cả vouchers\n\n'
              '✅ GIỮ LẠI:\n'
              '- Users (tài khoản)\n\n'
              'Hành động này KHÔNG THỂ HOÀN TÁC!',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('XÓA HẾT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
      _status = 'Đang xóa dữ liệu...';
    });

    try {
      await FirebaseCleanup.deleteAllData();

      if (mounted) {
        setState(() {
          _status = '✅ Đã xóa hết dữ liệu!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa hết dữ liệu cũ!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ Lỗi: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _createSampleData() async {
    setState(() {
      _isProcessing = true;
      _status = 'Đang tạo dữ liệu mẫu...';
    });

    try {
      await FirebaseCleanup.createSampleData();

      if (mounted) {
        setState(() {
          _status = '✅ Đã tạo dữ liệu mẫu!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tạo dữ liệu mẫu thành công!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ Lỗi: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _verifyData() async {
    setState(() {
      _isProcessing = true;
      _status = 'Đang kiểm tra dữ liệu...';
    });

    try {
      await FirebaseCleanup.verifyDataStructure();

      if (mounted) {
        setState(() {
          _status = '✅ Kiểm tra hoàn tất! Xem logs.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã kiểm tra xong! Xem logs trong console.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ Lỗi: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ✅ NÚT MỚI: FIX TOÀN BỘ DATABASE
  Future<void> _fixCompleteDatabase() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.build, color: Color(0xFF4CAF50), size: 32),
            SizedBox(width: 12),
            Text('FIX DATABASE?', style: TextStyle(color: Color(0xFF4CAF50))),
          ],
        ),
        content: const Text(
          'Công cụ này sẽ:\n\n'
              '1️⃣ XÓA tất cả data BỊ LỖI\n'
              '2️⃣ KIỂM TRA cấu trúc\n'
              '3️⃣ TẠO sample data nếu DB trống\n\n'
              '✅ GIỮ LẠI data hợp lệ\n'
              '✅ KHÔNG XÓA users\n\n'
              'Bạn có muốn tiếp tục?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('FIX NGAY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
      _status = 'Đang fix database...';
    });

    try {
      await CompleteDatabaseFix.fixCompleteDatabase();

      if (mounted) {
        setState(() {
          _status = '✅ DATABASE ĐÃ ĐƯỢC FIX!';
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
                SizedBox(width: 12),
                Text('FIX THÀNH CÔNG!', style: TextStyle(color: Color(0xFF4CAF50))),
              ],
            ),
            content: const Text(
              'Database đã được sửa chữa!\n\n'
                  '✅ Xóa data lỗi\n'
                  '✅ Kiểm tra cấu trúc\n'
                  '✅ Tạo sample data\n\n'
                  'Giờ bạn có thể sử dụng app bình thường!',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ Lỗi: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ✅ DIAGNOSTIC CHECK
  Future<void> _diagnosticCheck() async {
    setState(() {
      _isProcessing = true;
      _status = 'Đang chẩn đoán...';
    });

    try {
      await CompleteDatabaseFix.diagnosticCheck();

      if (mounted) {
        setState(() {
          _status = '✅ Xem chi tiết trong console logs';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã chẩn đoán xong! Xem logs.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ Lỗi: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _doFullReset() async {
    // Confirm
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('RESET TOÀN BỘ?', style: TextStyle(color: Colors.red)),
        content: const Text(
          'Thao tác này sẽ:\n\n'
              '1. XÓA HẾT dữ liệu cũ\n'
              '2. TẠO LẠI dữ liệu mẫu mới\n'
              '3. VERIFY cấu trúc\n\n'
              'Bạn có chắc chắn?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('RESET TOÀN BỘ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
      _status = 'Đang reset toàn bộ...';
    });

    try {
      // Step 1: Delete
      setState(() => _status = '1/3: Đang xóa dữ liệu cũ...');
      await FirebaseCleanup.deleteAllData();

      await Future.delayed(const Duration(seconds: 2));

      // Step 2: Create
      setState(() => _status = '2/3: Đang tạo dữ liệu mới...');
      await FirebaseCleanup.createSampleData();

      await Future.delayed(const Duration(seconds: 1));

      // Step 3: Verify
      setState(() => _status = '3/3: Đang kiểm tra...');
      await FirebaseCleanup.verifyDataStructure();

      if (mounted) {
        setState(() {
          _status = '✅ HOÀN TẤT! Database đã được reset.';
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
                SizedBox(width: 12),
                Text('THÀNH CÔNG!', style: TextStyle(color: Color(0xFF4CAF50))),
              ],
            ),
            content: const Text(
              'Database đã được reset hoàn toàn!\n\n'
                  '✅ Dữ liệu cũ đã xóa\n'
                  '✅ Dữ liệu mẫu đã tạo\n'
                  '✅ Cấu trúc đã kiểm tra\n\n'
                  'Giờ bạn có thể sử dụng app bình thường!',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ Lỗi: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Database Cleanup'),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  children: [
                    if (_isProcessing)
                      const CircularProgressIndicator(color: Color(0xFFE50914)),
                    if (_isProcessing) const SizedBox(height: 16),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Quick action button
              _buildActionButton(
                '🔧 FIX DATABASE (Khuyên dùng)',
                'Tự động sửa data lỗi + Tạo sample',
                const Color(0xFF4CAF50),
                _fixCompleteDatabase,
                isMain: true,
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFF2A2A2A)),
              const SizedBox(height: 16),

              const Text(
                'Công cụ khác:',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 16),

              // Diagnostic check
              _buildActionButton(
                '🔍 Chẩn Đoán Chi Tiết',
                'Xem chi tiết cấu trúc database',
                const Color(0xFF2196F3),
                _diagnosticCheck,
              ),

              const SizedBox(height: 12),

              // Full Reset
              _buildActionButton(
                '🔄 RESET TOÀN BỘ',
                'Xóa hết + Tạo mới + Verify',
                Colors.red,
                _doFullReset,
              ),

              const SizedBox(height: 12),

              // Individual actions
              _buildActionButton(
                '🗑️ Xóa Hết Dữ Liệu',
                'Xóa tất cả data (trừ users)',
                const Color(0xFFE50914),
                _deleteAllData,
              ),

              const SizedBox(height: 12),

              _buildActionButton(
                '📝 Tạo Dữ Liệu Mẫu',
                'Tạo movies, theaters, showtimes mẫu',
                const Color(0xFF4CAF50),
                _createSampleData,
              ),

              const SizedBox(height: 12),

              _buildActionButton(
                '🔍 Kiểm Tra Cấu Trúc',
                'Verify data trong Firebase',
                const Color(0xFF2196F3),
                _verifyData,
              ),

              const Spacer(),

              // Warning
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cẩn thận! Các thao tác này sẽ thay đổi dữ liệu trong Firebase!',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String title,
      String subtitle,
      Color color,
      VoidCallback onPressed, {
        bool isMain = false,
      }) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey[800],
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: isMain ? 8 : 2,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMain ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}