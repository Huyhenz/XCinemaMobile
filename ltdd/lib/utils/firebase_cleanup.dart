// File: lib/utils/firebase_cleanup.dart
// Script để xóa hết data cũ và tạo lại đúng format

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseCleanup {
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// XÓA HẾT DỮ LIỆU CŨ - CẢNH BÁO: SẼ XÓA TẤT CẢ!
  static Future<void> deleteAllData() async {
    print('🗑️ ==================== DELETING ALL DATA ====================');
    print('⚠️ WARNING: This will delete ALL data in Firebase!');

    try {
      // Xóa tất cả nodes
      await _db.child('bookings').remove();
      print('✅ Deleted all bookings');

      await _db.child('temp_bookings').remove();
      print('✅ Deleted all temp bookings');

      await _db.child('showtimes').remove();
      print('✅ Deleted all showtimes');

      await _db.child('movies').remove();
      print('✅ Deleted all movies');

      await _db.child('theaters').remove();
      print('✅ Deleted all theaters');

      await _db.child('payments').remove();
      print('✅ Deleted all payments');

      await _db.child('notifications').remove();
      print('✅ Deleted all notifications');

      await _db.child('vouchers').remove();
      print('✅ Deleted all vouchers');

      // KHÔNG XÓA users vì sẽ mất tài khoản
      // await _db.child('users').remove();

      print('✅ All data deleted successfully!');
      print('🗑️ ============================================================\n');
    } catch (e) {
      print('❌ Error deleting data: $e');
    }
  }

  /// TẠO DỮ LIỆU MẪU ĐÚNG FORMAT
  static Future<void> createSampleData() async {
    print('📝 ==================== CREATING SAMPLE DATA ====================');

    try {
      // 1. TẠO THEATERS
      print('\n🎭 Creating theaters...');
      String theater1Id = await _createTheater('Theater 1', 10); // A1-A5, B1-B5
      String theater2Id = await _createTheater('Theater 2', 8);  // A1-A4, B1-B4
      print('✅ Created ${[theater1Id, theater2Id].length} theaters');

      // 2. TẠO MOVIES
      print('\n🎬 Creating movies...');
      String movie1Id = await _createMovie(
        'The Matrix Resurrections',
        'Trở lại thế giới Matrix đầy kịch tính',
        'Action, Sci-Fi',
        148,
        'https://image.tmdb.org/t/p/w500/8c4a8kE7PizaGQQnditMmI1xbRp.jpg',
      );

      String movie2Id = await _createMovie(
        'Spider-Man: No Way Home',
        'Peter Parker đối mặt với đa vũ trụ',
        'Action, Adventure',
        148,
        'https://image.tmdb.org/t/p/w500/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg',
      );

      String movie3Id = await _createMovie(
        'Dune',
        'Hành tinh cát huyền bí',
        'Sci-Fi, Adventure',
        155,
        'https://image.tmdb.org/t/p/w500/d5NXSklXo0qyIYkgV94XAgMIckC.jpg',
      );
      print('✅ Created 3 movies');

      // 3. TẠO SHOWTIMES
      print('\n⏰ Creating showtimes...');
      List<String> showtimeIds = [];

      // Movie 1 - 3 showtimes
      for (int i = 0; i < 3; i++) {
        String id = await _createShowtime(
          movie1Id,
          theater1Id,
          DateTime.now().add(Duration(days: 1, hours: 10 + i * 3)),
          50000,
        );
        showtimeIds.add(id);
      }

      // Movie 2 - 3 showtimes
      for (int i = 0; i < 3; i++) {
        String id = await _createShowtime(
          movie2Id,
          theater2Id,
          DateTime.now().add(Duration(days: 1, hours: 9 + i * 3)),
          60000,
        );
        showtimeIds.add(id);
      }

      // Movie 3 - 2 showtimes
      for (int i = 0; i < 2; i++) {
        String id = await _createShowtime(
          movie3Id,
          theater1Id,
          DateTime.now().add(Duration(days: 2, hours: 14 + i * 3)),
          55000,
        );
        showtimeIds.add(id);
      }

      print('✅ Created ${showtimeIds.length} showtimes');

      // 4. TẠO VOUCHERS
      print('\n🎟️ Creating vouchers...');
      await _createVoucher('SAVE10', 10, 'percent');
      await _createVoucher('SAVE20K', 20000, 'fixed');
      await _createVoucher('VIP30', 30, 'percent');
      print('✅ Created 3 vouchers');

      print('\n✅ ==================== SAMPLE DATA CREATED ====================\n');
      print('📊 Summary:');
      print('   - Theaters: 2');
      print('   - Movies: 3');
      print('   - Showtimes: ${showtimeIds.length}');
      print('   - Vouchers: 3');
      print('   - Users: Kept existing');
      print('\n============================================================\n');

    } catch (e) {
      print('❌ Error creating sample data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // ===== HELPER METHODS =====

  static Future<String> _createTheater(String name, int seatsCount) async {
    final ref = _db.child('theaters').push();

    // Tạo danh sách ghế: A1-A5, B1-B5
    List<String> seats = [];
    int rows = (seatsCount / 5).ceil();
    for (int r = 0; r < rows; r++) {
      String rowLetter = String.fromCharCode('A'.codeUnitAt(0) + r);
      int seatsInRow = (r == rows - 1) ? (seatsCount - r * 5) : 5;
      for (int i = 1; i <= seatsInRow; i++) {
        seats.add('$rowLetter$i');
      }
    }

    // ✅ ĐẢM BẢO DATA LÀ MAP
    await ref.set({
      'name': name,
      'capacity': seatsCount,
      'seats': seats,
    });

    print('   ✅ Theater created: $name (${ref.key}) - $seatsCount seats');
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

    // ✅ ĐẢM BẢO DATA LÀ MAP
    await ref.set({
      'title': title,
      'description': description,
      'genre': genre,
      'duration': duration,
      'posterUrl': posterUrl,
      'releaseDate': ServerValue.timestamp,
    });

    print('   ✅ Movie created: $title (${ref.key})');
    return ref.key!;
  }

  static Future<String> _createShowtime(
      String movieId,
      String theaterId,
      DateTime startTime,
      double price,
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

    // ✅ ĐẢM BẢO DATA LÀ MAP
    await ref.set({
      'movieId': movieId,
      'theaterId': theaterId,
      'startTime': startTime.millisecondsSinceEpoch,
      'price': price,
      'availableSeats': seats,
    });

    print('   ✅ Showtime created: ${ref.key} - ${seats.length} seats');
    return ref.key!;
  }

  static Future<String> _createVoucher(
      String code,
      double discount,
      String type,
      ) async {
    final ref = _db.child('vouchers').child(code);

    // ✅ ĐẢM BẢO DATA LÀ MAP
    await ref.set({
      'discount': discount,
      'type': type,
      'expiryDate': DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch,
      'isActive': true,
    });

    print('   ✅ Voucher created: $code ($type: $discount)');
    return code;
  }

  /// VERIFY DATA STRUCTURE
  static Future<void> verifyDataStructure() async {
    print('🔍 ==================== VERIFYING DATA ====================');

    await _verifyNode('theaters');
    await _verifyNode('movies');
    await _verifyNode('showtimes');
    await _verifyNode('vouchers');

    print('🔍 ============================================================\n');
  }

  static Future<void> _verifyNode(String nodeName) async {
    try {
      DataSnapshot snapshot = await _db.child(nodeName).get();

      if (!snapshot.exists) {
        print('⚠️ $nodeName: Node does not exist');
        return;
      }

      final value = snapshot.value;

      if (value is! Map) {
        print('❌ $nodeName: ERROR - Not a Map! Type: ${value.runtimeType}');
        return;
      }

      Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
      print('✅ $nodeName: ${data.length} items');

      // Check first item
      if (data.isNotEmpty) {
        final firstKey = data.keys.first;
        final firstValue = data[firstKey];

        if (firstValue is! Map) {
          print('   ❌ ERROR: Item is ${firstValue.runtimeType}, should be Map!');
        } else {
          print('   ✅ Item structure is correct (Map)');
        }
      }

    } catch (e) {
      print('❌ $nodeName: Error - $e');
    }
  }
}