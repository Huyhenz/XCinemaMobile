// File: lib/utils/firebase_data_checker.dart
// Thêm file này để check và fix data trong Firebase

import 'package:firebase_database/firebase_database.dart';

class FirebaseDataChecker {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Check cấu trúc dữ liệu trong Firebase
  static Future<void> checkFirebaseStructure() async {
    print('🔍 ================== FIREBASE STRUCTURE CHECK ==================');

    // 1. Check movies
    await _checkNode('movies', 'Movie');

    // 2. Check theaters
    await _checkNode('theaters', 'Theater');

    // 3. Check showtimes
    await _checkNode('showtimes', 'Showtime');

    // 4. Check bookings
    await _checkNode('bookings', 'Booking');

    // 5. Check users
    await _checkNode('users', 'User');

    print('🔍 ============================================================\n');
  }

  static Future<void> _checkNode(String nodeName, String displayName) async {
    try {
      print('\n📂 Checking $displayName ($nodeName)...');

      DataSnapshot snapshot = await _db.child(nodeName).get();

      if (!snapshot.exists) {
        print('   ⚠️ Node does not exist');
        return;
      }

      if (snapshot.value == null) {
        print('   ⚠️ Node value is null');
        return;
      }

      final value = snapshot.value;

      if (value is String) {
        print('   ❌ ERROR: Node contains STRING instead of MAP!');
        print('   String value: "$value"');
        print('   → This is WRONG. Data should be: { "-N_key": { field: value } }');
        return;
      }

      if (value is Map) {
        Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
        print('   ✅ Node is valid Map with ${data.length} items');

        // Check first item structure
        if (data.isNotEmpty) {
          final firstKey = data.keys.first;
          final firstValue = data[firstKey];

          print('   📋 Sample item key: $firstKey');
          print('   📋 Sample item type: ${firstValue.runtimeType}');

          if (firstValue is Map) {
            print('   ✅ Item structure is correct (Map)');
            final fields = (firstValue as Map).keys.toList();
            print('   📋 Fields: ${fields.join(", ")}');
          } else if (firstValue is String) {
            print('   ❌ ERROR: Item is STRING, should be MAP!');
            print('   String value: "$firstValue"');
          } else {
            print('   ⚠️ Unexpected item type: ${firstValue.runtimeType}');
          }
        }

        return;
      }

      print('   ❌ Unexpected value type: ${value.runtimeType}');
      print('   Value: $value');

    } catch (e) {
      print('   ❌ Error checking node: $e');
    }
  }

  /// Fix dữ liệu sai trong Firebase (nếu cần)
  static Future<void> cleanInvalidData() async {
    print('🧹 ================== CLEANING INVALID DATA ==================');

    try {
      // Check và clean showtimes
      DataSnapshot showtimesSnapshot = await _db.child('showtimes').get();
      if (showtimesSnapshot.exists && showtimesSnapshot.value != null) {
        final value = showtimesSnapshot.value;

        if (value is Map) {
          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);

          for (var entry in data.entries) {
            final key = entry.key;
            final itemValue = entry.value;

            // Nếu item là String thay vì Map, xóa nó đi
            if (itemValue is String) {
              print('🗑️ Deleting invalid showtime: $key (type: String)');
              await _db.child('showtimes').child(key.toString()).remove();
            } else if (itemValue is! Map) {
              print('🗑️ Deleting invalid showtime: $key (type: ${itemValue.runtimeType})');
              await _db.child('showtimes').child(key.toString()).remove();
            }
          }
        }
      }

      // Check và clean bookings
      DataSnapshot bookingsSnapshot = await _db.child('bookings').get();
      if (bookingsSnapshot.exists && bookingsSnapshot.value != null) {
        final value = bookingsSnapshot.value;

        if (value is Map) {
          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);

          for (var entry in data.entries) {
            final key = entry.key;
            final itemValue = entry.value;

            if (itemValue is String) {
              print('🗑️ Deleting invalid booking: $key (type: String)');
              await _db.child('bookings').child(key.toString()).remove();
            } else if (itemValue is! Map) {
              print('🗑️ Deleting invalid booking: $key (type: ${itemValue.runtimeType})');
              await _db.child('bookings').child(key.toString()).remove();
            }
          }
        }
      }

      print('✅ Cleaning completed');
      print('🧹 ============================================================\n');

    } catch (e) {
      print('❌ Error cleaning data: $e');
    }
  }

  /// Test tạo showtime mẫu đúng format
  static Future<void> createSampleShowtime(String movieId, String theaterId) async {
    try {
      print('📝 Creating sample showtime...');

      final ref = _db.child('showtimes').push();

      // Đảm bảo data là Map, KHÔNG phải String
      await ref.set({
        'movieId': movieId,
        'theaterId': theaterId,
        'startTime': DateTime.now().add(Duration(days: 1)).millisecondsSinceEpoch,
        'price': 50000.0,
        'availableSeats': ['A1', 'A2', 'A3', 'A4', 'A5', 'B1', 'B2', 'B3', 'B4', 'B5'],
      });

      print('✅ Sample showtime created: ${ref.key}');

      // Verify
      DataSnapshot check = await ref.get();
      if (check.value is Map) {
        print('✅ Verified: Data is Map (correct)');
      } else {
        print('❌ ERROR: Data is ${check.value.runtimeType} (wrong!)');
      }

    } catch (e) {
      print('❌ Error creating sample showtime: $e');
    }
  }
}

// ============================================================
// CÁC ADD VÀO ADMIN SCREEN ĐỂ TEST
// ============================================================

/*
// Thêm vào admin_dashboard_screen.dart trong actions của AppBar:

actions: [
  // Button để check Firebase structure
  IconButton(
    icon: Icon(Icons.bug_report),
    tooltip: 'Check Firebase Data',
    onPressed: () async {
      await FirebaseDataChecker.checkFirebaseStructure();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check logs in console')),
      );
    },
  ),

  // Button để clean invalid data
  IconButton(
    icon: Icon(Icons.cleaning_services),
    tooltip: 'Clean Invalid Data',
    onPressed: () async {
      await FirebaseDataChecker.cleanInvalidData();
      await FirebaseDataChecker.checkFirebaseStructure();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cleaning completed. Check logs.')),
      );
    },
  ),
],
*/