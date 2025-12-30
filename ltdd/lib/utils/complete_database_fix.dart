// File: lib/utils/complete_database_fix.dart
// CÔNG CỤ FIX TOÀN BỘ DATABASE

import 'package:firebase_database/firebase_database.dart';

class CompleteDatabaseFix {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// 🔧 FIX TOÀN BỘ DATABASE - Xóa data lỗi và tạo lại
  static Future<void> fixCompleteDatabase() async {
    print('\n🔧 ==================== COMPLETE DATABASE FIX ====================');
    print('⚠️  This will fix all invalid data in Firebase');

    try {
      // Step 1: Clean invalid data
      print('\n📋 Step 1: Cleaning invalid data...');
      await _cleanInvalidNodes();

      // Step 2: Verify structure
      print('\n📋 Step 2: Verifying structure...');
      await _verifyAllNodes();

      // Step 3: Create sample data if needed
      print('\n📋 Step 3: Checking if sample data needed...');
      bool needsSampleData = await _checkIfNeedsSampleData();

      if (needsSampleData) {
        print('   ⚠️  Database is empty, creating sample data...');
        await _createCompleteSampleData();
      } else {
        print('   ✅ Database has data, skipping sample creation');
      }

      print('\n✅ ==================== FIX COMPLETED ====================\n');

    } catch (e) {
      print('❌ Error during fix: $e');
      print('Stack: ${StackTrace.current}');
    }
  }

  /// Xóa tất cả data không hợp lệ
  static Future<void> _cleanInvalidNodes() async {
    final nodes = ['movies', 'theaters', 'showtimes', 'bookings', 'temp_bookings',
      'payments', 'notifications', 'vouchers'];

    for (String nodeName in nodes) {
      await _cleanNode(nodeName);
    }
  }

  static Future<void> _cleanNode(String nodeName) async {
    try {
      DataSnapshot snapshot = await _db.child(nodeName).get();

      if (!snapshot.exists || snapshot.value == null) {
        print('   ℹ️  $nodeName: Empty or doesn\'t exist');
        return;
      }

      final value = snapshot.value;

      // Nếu toàn bộ node là String -> XÓA
      if (value is String) {
        print('   🗑️  $nodeName: DELETING entire node (is String)');
        await _db.child(nodeName).remove();
        return;
      }

      // Nếu là Map, check từng item
      if (value is Map) {
        Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
        int deletedCount = 0;

        for (var entry in data.entries) {
          final key = entry.key;
          final itemValue = entry.value;

          // Xóa item nếu không phải Map
          if (itemValue is! Map) {
            print('   🗑️  $nodeName/$key: Deleting (type: ${itemValue.runtimeType})');
            await _db.child(nodeName).child(key.toString()).remove();
            deletedCount++;
          }
        }

        if (deletedCount > 0) {
          print('   ✅ $nodeName: Cleaned $deletedCount invalid items');
        } else {
          print('   ✅ $nodeName: All items valid (${data.length} items)');
        }
      }

    } catch (e) {
      print('   ❌ Error cleaning $nodeName: $e');
    }
  }

  /// Verify tất cả nodes
  static Future<void> _verifyAllNodes() async {
    final nodes = ['movies', 'theaters', 'showtimes', 'bookings', 'vouchers'];

    for (String nodeName in nodes) {
      await _verifyNode(nodeName);
    }
  }

  static Future<void> _verifyNode(String nodeName) async {
    try {
      DataSnapshot snapshot = await _db.child(nodeName).get();

      if (!snapshot.exists || snapshot.value == null) {
        print('   📦 $nodeName: Empty');
        return;
      }

      final value = snapshot.value;

      if (value is! Map) {
        print('   ❌ $nodeName: ERROR - Not a Map!');
        return;
      }

      Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
      print('   ✅ $nodeName: ${data.length} valid items');

    } catch (e) {
      print('   ❌ $nodeName: Error - $e');
    }
  }

  /// Check xem có cần tạo sample data không
  static Future<bool> _checkIfNeedsSampleData() async {
    try {
      DataSnapshot moviesSnapshot = await _db.child('movies').get();
      DataSnapshot theatersSnapshot = await _db.child('theaters').get();
      DataSnapshot showtimesSnapshot = await _db.child('showtimes').get();

      bool hasMovies = moviesSnapshot.exists &&
          moviesSnapshot.value != null &&
          moviesSnapshot.value is Map;
      bool hasTheaters = theatersSnapshot.exists &&
          theatersSnapshot.value != null &&
          theatersSnapshot.value is Map;
      bool hasShowtimes = showtimesSnapshot.exists &&
          showtimesSnapshot.value != null &&
          showtimesSnapshot.value is Map;

      return !hasMovies || !hasTheaters || !hasShowtimes;

    } catch (e) {
      print('Error checking data: $e');
      return true;
    }
  }

  /// Tạo toàn bộ sample data
  static Future<void> _createCompleteSampleData() async {
    print('\n📝 Creating complete sample data...\n');

    try {
      // 1. Tạo Theaters
      print('🎭 Creating theaters...');
      String theater1Id = await _createTheater('CGV Vincom', 50);
      String theater2Id = await _createTheater('Lotte Cinema', 40);
      String theater3Id = await _createTheater('Galaxy Cinema', 60);
      print('   ✅ Created 3 theaters\n');

      // 2. Tạo Movies
      print('🎬 Creating movies...');
      List<Map<String, dynamic>> movieData = [
        {
          'title': 'Avatar: The Way of Water',
          'description': 'Jake Sully sống cùng gia đình mới trên hành tinh Pandora',
          'genre': 'Action, Adventure, Fantasy',
          'duration': 192,
          'posterUrl': 'https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
        },
        {
          'title': 'The Batman',
          'description': 'Batman phải đối mặt với Riddler và bí mật đen tối của Gotham',
          'genre': 'Action, Crime, Drama',
          'duration': 176,
          'posterUrl': 'https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg',
        },
        {
          'title': 'Top Gun: Maverick',
          'description': 'Maverick trở lại với nhiệm vụ huấn luyện thế hệ phi công mới',
          'genre': 'Action, Drama',
          'duration': 131,
          'posterUrl': 'https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
        },
        {
          'title': 'Spider-Man: No Way Home',
          'description': 'Peter Parker đối mặt với đa vũ trụ',
          'genre': 'Action, Adventure',
          'duration': 148,
          'posterUrl': 'https://image.tmdb.org/t/p/w500/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg',
        },
        {
          'title': 'Dune',
          'description': 'Hành tinh cát huyền bí Arrakis',
          'genre': 'Sci-Fi, Adventure',
          'duration': 155,
          'posterUrl': 'https://image.tmdb.org/t/p/w500/d5NXSklXo0qyIYkgV94XAgMIckC.jpg',
        },
      ];

      List<String> movieIds = [];
      for (var movie in movieData) {
        String id = await _createMovie(
          movie['title'],
          movie['description'],
          movie['genre'],
          movie['duration'],
          movie['posterUrl'],
        );
        movieIds.add(id);
      }
      print('   ✅ Created ${movieIds.length} movies\n');

      // 3. Tạo Showtimes
      print('⏰ Creating showtimes...');
      List<String> theaterIds = [theater1Id, theater2Id, theater3Id];
      int showtimeCount = 0;

      for (String movieId in movieIds) {
        // Mỗi phim 3-4 suất chiếu ở các rạp khác nhau
        for (int i = 0; i < 3; i++) {
          String theaterId = theaterIds[i % theaterIds.length];

          // Tạo suất chiếu vào các ngày khác nhau
          for (int day = 0; day < 2; day++) {
            DateTime showtime = DateTime.now().add(
              Duration(days: day + 1, hours: 10 + (i * 3)),
            );

            await _createShowtime(movieId, theaterId, showtime);
            showtimeCount++;
          }
        }
      }
      print('   ✅ Created $showtimeCount showtimes\n');

      // 4. Tạo Vouchers
      print('🎟️ Creating vouchers...');
      await _createVoucher('SAVE10', 10, 'percent');
      await _createVoucher('SAVE20K', 20000, 'fixed');
      await _createVoucher('VIP30', 30, 'percent');
      await _createVoucher('FREESHIP', 15000, 'fixed');
      print('   ✅ Created 4 vouchers\n');

      print('✅ Sample data creation completed!\n');

    } catch (e) {
      print('❌ Error creating sample data: $e');
    }
  }

  // ===== HELPER METHODS =====

  static Future<String> _createTheater(String name, int capacity) async {
    final ref = _db.child('theaters').push();

    // Tạo ghế: A1-A10, B1-B10, etc
    List<String> seats = [];
    int seatsPerRow = 10;
    int rows = (capacity / seatsPerRow).ceil();

    for (int r = 0; r < rows; r++) {
      String rowLetter = String.fromCharCode('A'.codeUnitAt(0) + r);
      int seatsInThisRow = (r == rows - 1) ? (capacity - r * seatsPerRow) : seatsPerRow;

      for (int i = 1; i <= seatsInThisRow; i++) {
        seats.add('$rowLetter$i');
      }
    }

    await ref.set({
      'name': name,
      'capacity': capacity,
      'seats': seats,
    });

    print('   ✅ Theater: $name (${seats.length} seats)');
    return ref.key!;
  }

  static Future<String> _createMovie(
      String title,
      String description,
      String genre,
      int duration,
      String posterUrl,
      ) async {
    final ref = _db.child('movies').push();

    await ref.set({
      'title': title,
      'description': description,
      'genre': genre,
      'duration': duration,
      'posterUrl': posterUrl,
      'releaseDate': ServerValue.timestamp,
    });

    print('   ✅ Movie: $title');
    return ref.key!;
  }

  static Future<String> _createShowtime(
      String movieId,
      String theaterId,
      DateTime startTime,
      ) async {
    final ref = _db.child('showtimes').push();

    // Lấy danh sách ghế từ theater
    DataSnapshot theaterSnapshot = await _db.child('theaters').child(theaterId).get();
    List<String> seats = [];

    if (theaterSnapshot.exists && theaterSnapshot.value is Map) {
      Map<dynamic, dynamic> theaterData = Map<dynamic, dynamic>.from(theaterSnapshot.value as Map);
      if (theaterData['seats'] is List) {
        seats = List<String>.from(theaterData['seats'] as List);
      }
    }

    await ref.set({
      'movieId': movieId,
      'theaterId': theaterId,
      'startTime': startTime.millisecondsSinceEpoch,
      'availableSeats': seats,
    });

    return ref.key!;
  }

  static Future<String> _createVoucher(
      String code,
      double discount,
      String type,
      ) async {
    final ref = _db.child('vouchers').child(code);

    await ref.set({
      'discount': discount,
      'type': type,
      'expiryDate': DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch,
      'isActive': true,
    });

    print('   ✅ Voucher: $code ($type: $discount)');
    return code;
  }

  /// 🔍 DIAGNOSTIC - Chi tiết kiểm tra database
  static Future<void> diagnosticCheck() async {
    print('\n🔍 ==================== DIAGNOSTIC CHECK ====================\n');

    final nodes = ['movies', 'theaters', 'showtimes', 'bookings', 'temp_bookings',
      'payments', 'notifications', 'vouchers', 'users'];

    for (String nodeName in nodes) {
      await _diagnosticNode(nodeName);
    }

    print('\n🔍 ============================================================\n');
  }

  static Future<void> _diagnosticNode(String nodeName) async {
    try {
      print('📂 $nodeName:');
      DataSnapshot snapshot = await _db.child(nodeName).get();

      if (!snapshot.exists || snapshot.value == null) {
        print('   ➜ Status: Empty\n');
        return;
      }

      final value = snapshot.value;
      print('   ➜ Type: ${value.runtimeType}');

      if (value is String) {
        print('   ➜ ❌ ERROR: Entire node is STRING!');
        print('   ➜ Value: "$value"');
        print('   ➜ Action: MUST DELETE and recreate\n');
        return;
      }

      if (value is Map) {
        Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
        print('   ➜ Count: ${data.length} items');

        int validCount = 0;
        int invalidCount = 0;

        data.forEach((key, itemValue) {
          if (itemValue is Map) {
            validCount++;
          } else {
            invalidCount++;
            print('   ➜ ❌ Invalid item: $key (${itemValue.runtimeType})');
          }
        });

        print('   ➜ Valid: $validCount');
        print('   ➜ Invalid: $invalidCount');

        if (invalidCount > 0) {
          print('   ➜ Action: Clean invalid items\n');
        } else {
          print('   ➜ ✅ All items valid\n');
        }
      } else {
        print('   ➜ ❌ Unexpected type: ${value.runtimeType}\n');
      }

    } catch (e) {
      print('   ➜ ❌ Error: $e\n');
    }
  }
}