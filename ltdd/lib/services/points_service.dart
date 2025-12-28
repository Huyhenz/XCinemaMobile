// File: lib/services/points_service.dart
// Service để quản lý tích điểm và đổi voucher

import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user.dart';
import '../models/voucher.dart';
import 'database_services.dart';

class PointsService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final DatabaseService _dbService = DatabaseService();

  // Tích điểm khi đặt vé thành công (3-4 điểm ngẫu nhiên)
  Future<void> addPointsForBooking(String userId) async {
    try {
      final random = Random();
      final points = 3 + random.nextInt(2); // 3-4 điểm
      
      await _addPoints(userId, points, 'Đặt vé xem phim');
      print('✅ Đã tích $points điểm cho user $userId (đặt vé)');
    } catch (e) {
      print('❌ Error adding points for booking: $e');
    }
  }

  // Tích điểm khi đánh giá phim (1-2 điểm ngẫu nhiên)
  Future<void> addPointsForRating(String userId) async {
    try {
      final random = Random();
      final points = 1 + random.nextInt(2); // 1-2 điểm
      
      await _addPoints(userId, points, 'Đánh giá phim');
      print('✅ Đã tích $points điểm cho user $userId (đánh giá phim)');
    } catch (e) {
      print('❌ Error adding points for rating: $e');
    }
  }

  // Thêm điểm vào tài khoản user
  Future<void> _addPoints(String userId, int points, String reason) async {
    try {
      // Lấy user hiện tại
      UserModel? user = await _dbService.getUser(userId);
      if (user == null) {
        print('⚠️ User not found: $userId');
        return;
      }

      // Cập nhật điểm
      final newPoints = user.points + points;
      await _db.child('users').child(userId).update({
        'points': newPoints,
      });

      print('💰 User $userId: ${user.points} + $points = $newPoints điểm ($reason)');
    } catch (e) {
      print('❌ Error adding points: $e');
      rethrow;
    }
  }

  // Trừ điểm khi đổi voucher
  Future<void> deductPoints(String userId, int points) async {
    try {
      UserModel? user = await _dbService.getUser(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      if (user.points < points) {
        throw Exception('Không đủ điểm để đổi voucher');
      }

      final newPoints = user.points - points;
      await _db.child('users').child(userId).update({
        'points': newPoints,
      });

      print('💰 User $userId: ${user.points} - $points = $newPoints điểm (đổi voucher)');
    } catch (e) {
      print('❌ Error deducting points: $e');
      rethrow;
    }
  }

  // Đổi voucher bằng điểm
  Future<String> redeemVoucherWithPoints(String userId, String voucherId) async {
    try {
      // Lấy voucher
      VoucherModel? voucher = await _dbService.getVoucher(voucherId);
      if (voucher == null) {
        throw Exception('Voucher không tồn tại');
      }

      if (voucher.points == null) {
        throw Exception('Voucher này không thể đổi bằng điểm');
      }

      // Kiểm tra điểm
      UserModel? user = await _dbService.getUser(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      if (user.points < voucher.points!) {
        throw Exception('Không đủ điểm để đổi voucher. Cần ${voucher.points} điểm, bạn có ${user.points} điểm');
      }

      // Kiểm tra voucher còn hạn không
      final now = DateTime.now().millisecondsSinceEpoch;
      if (voucher.expiryDate < now) {
        throw Exception('Voucher đã hết hạn');
      }

      if (!voucher.isActive) {
        throw Exception('Voucher không còn hoạt động');
      }

      // Trừ điểm
      await deductPoints(userId, voucher.points!);

      // Lưu voucher đã đổi vào user_vouchers
      final ref = _db.child('user_vouchers').child(userId).child(voucherId).push();
      await ref.set({
        'voucherId': voucherId,
        'redeemedAt': ServerValue.timestamp,
        'isUsed': false,
      });

      print('✅ User $userId đã đổi voucher $voucherId với ${voucher.points} điểm');
      return ref.key!;
    } catch (e) {
      print('❌ Error redeeming voucher: $e');
      rethrow;
    }
  }

  // Lấy danh sách voucher có thể đổi bằng điểm
  Future<List<VoucherModel>> getRedeemableVouchers() async {
    try {
      final allVouchers = await _dbService.getAllVouchers();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      return allVouchers.where((voucher) {
        return voucher.isActive &&
               voucher.points != null &&
               voucher.expiryDate > now;
      }).toList();
    } catch (e) {
      print('❌ Error getting redeemable vouchers: $e');
      return [];
    }
  }

  // Lấy danh sách voucher đã đổi của user
  Future<List<Map<String, dynamic>>> getUserRedeemedVouchers(String userId) async {
    try {
      DataSnapshot snapshot = await _db.child('user_vouchers').child(userId).get();
      List<Map<String, dynamic>> redeemedVouchers = [];

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;
        if (value is Map) {
          value.forEach((voucherId, voucherData) {
            if (voucherData is Map) {
              final data = Map<String, dynamic>.from(voucherData);
              data['voucherId'] = voucherId;
              redeemedVouchers.add(data);
            }
          });
        }
      }

      // Lấy thông tin chi tiết voucher
      List<Map<String, dynamic>> result = [];
      for (var redeemed in redeemedVouchers) {
        final voucherId = redeemed['voucherId']?.toString();
        if (voucherId != null) {
          final voucher = await _dbService.getVoucher(voucherId);
          if (voucher != null && !(redeemed['isUsed'] ?? false)) {
            result.add({
              'voucher': voucher,
              'redeemedAt': redeemed['redeemedAt'],
              'isUsed': redeemed['isUsed'] ?? false,
            });
          }
        }
      }

      return result;
    } catch (e) {
      print('❌ Error getting user redeemed vouchers: $e');
      return [];
    }
  }

  // Đánh dấu voucher đã sử dụng
  Future<void> markVoucherAsUsed(String userId, String voucherId) async {
    try {
      DataSnapshot snapshot = await _db.child('user_vouchers').child(userId).child(voucherId).get();
      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;
        if (value is Map) {
          value.forEach((key, data) {
            if (data is Map && !(data['isUsed'] ?? false)) {
              _db.child('user_vouchers').child(userId).child(voucherId).child(key.toString()).update({
                'isUsed': true,
                'usedAt': ServerValue.timestamp,
              });
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error marking voucher as used: $e');
    }
  }

  // Nhận voucher ngẫu nhiên (free voucher, không cần điểm)
  Future<VoucherModel?> getRandomFreeVoucher() async {
    try {
      final allVouchers = await _dbService.getAllVouchers();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Lọc voucher free (points == null) và còn hạn
      final freeVouchers = allVouchers.where((voucher) {
        return voucher.isActive &&
               voucher.points == null &&
               voucher.expiryDate > now;
      }).toList();

      if (freeVouchers.isEmpty) {
        return null;
      }

      final random = Random();
      return freeVouchers[random.nextInt(freeVouchers.length)];
    } catch (e) {
      print('❌ Error getting random free voucher: $e');
      return null;
    }
  }

  // Lưu voucher ngẫu nhiên vào user
  Future<void> addRandomVoucherToUser(String userId, String voucherId) async {
    try {
      final ref = _db.child('user_vouchers').child(userId).child(voucherId).push();
      await ref.set({
        'voucherId': voucherId,
        'redeemedAt': ServerValue.timestamp,
        'isUsed': false,
        'source': 'random', // Đánh dấu là voucher ngẫu nhiên
      });
      print('✅ Đã thêm voucher ngẫu nhiên $voucherId cho user $userId');
    } catch (e) {
      print('❌ Error adding random voucher to user: $e');
      rethrow;
    }
  }
}

