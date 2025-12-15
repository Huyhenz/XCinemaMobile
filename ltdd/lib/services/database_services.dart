// File: lib/services/database_services.dart (giữ nguyên Realtime Database cho tất cả)
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Nếu cần UID từ Auth
import '../models/booking.dart'; // Import tất cả models
import '../models/movie.dart';
import '../models/showtime.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../models/theater.dart';
import '../models/voucher.dart';
import '../models/tempbooking.dart';
import '../models/user.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid; // Lấy UID nếu đã auth

// Các method sẽ được thêm ở dưới
//USER
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.child('users').child(user.id).set(user.toMap());
    } catch (e) {
      // Xử lý lỗi, ví dụ: throw Exception('Lỗi lưu user: $e');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      DataSnapshot snapshot = await _db.child('users').child(userId).get();
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.value as Map<dynamic, dynamic>, userId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserPhone(String userId, String newPhone) async {
    await _db.child('users').child(userId).update({'phone': newPhone});
  }

  Future<void> deleteUser(String userId) async {
    await _db.child('users').child(userId).remove();
  }

  Stream<UserModel?> listenCurrentUser() {
    if (_currentUserId == null) return Stream.value(null);
    return _db.child('users').child(_currentUserId!).onValue.map((event) {
      if (event.snapshot.exists) {
        return UserModel.fromMap(event.snapshot.value as Map<dynamic, dynamic>, _currentUserId!);
      }
      return null;
    });
  }

  //MOVIE
  Future<String> saveMovie(MovieModel movie) async {
    final ref = _db.child('movies').push(); // Generate ID
    await ref.set(movie.toMap());
    return ref.key!; // Trả về ID mới
  }

  Future<MovieModel?> getMovie(String movieId) async {
    DataSnapshot snapshot = await _db.child('movies').child(movieId).get();
    if (snapshot.exists) {
      return MovieModel.fromMap(snapshot.value as Map<dynamic, dynamic>, movieId);
    }
    return null;
  }

  Future<List<MovieModel>> getAllMovies() async {
    DataSnapshot snapshot = await _db.child('movies').get();
    List<MovieModel> movies = [];
    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        movies.add(MovieModel.fromMap(value, key));
      });
    }
    return movies;
  }

  //SHOWTIME
  Future<String> saveShowtime(ShowtimeModel showtime) async {
    final ref = _db.child('showtimes').push();
    await ref.set(showtime.toMap());
    return ref.key!;
  }

  Future<ShowtimeModel?> getShowtime(String showtimeId) async {
    DataSnapshot snapshot = await _db.child('showtimes').child(showtimeId).get();
    if (snapshot.exists) {
      return ShowtimeModel.fromMap(snapshot.value as Map<dynamic, dynamic>, showtimeId);
    }
    return null;
  }

  Future<List<ShowtimeModel>> getShowtimesByMovie(String movieId) async {
    Query query = _db.child('showtimes').orderByChild('movieId').equalTo(movieId);
    DataSnapshot snapshot = await query.get();
    List<ShowtimeModel> showtimes = [];
    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        showtimes.add(ShowtimeModel.fromMap(value, key));
      });
    }
    return showtimes;
  }

  Future<void> updateShowtimeSeats(String showtimeId, List<String> newAvailableSeats) async {
    await _db.child('showtimes').child(showtimeId).update({'availableSeats': newAvailableSeats});
  }

  //TEMP BOOKING
  Future<String> saveTempBooking(TempBookingModel temp) async {
    final ref = _db.child('temp_bookings').push();
    await ref.set(temp.toMap());
    String tempId = ref.key!;

    // Remove seats from showtime availableSeats
    ShowtimeModel? showtime = await getShowtime(temp.showtimeId);
    if (showtime != null) {
      List<String> updatedSeats = List.from(showtime.availableSeats)..removeWhere((seat) => temp.seats.contains(seat));
      await updateShowtimeSeats(temp.showtimeId, updatedSeats);
    }

    return tempId;
  }

  Future<TempBookingModel?> getTempBooking(String tempId) async {
    DataSnapshot snapshot = await _db.child('temp_bookings').child(tempId).get();
    if (snapshot.exists) {
      return TempBookingModel.fromMap(snapshot.value as Map<dynamic, dynamic>, tempId);
    }
    return null;
  }

  Future<void> deleteTempBooking(String tempId, {bool addBackSeats = true}) async {
    TempBookingModel? temp = await getTempBooking(tempId);
    if (temp != null && temp.status == 'active' && addBackSeats) {
      // Add seats back to showtime availableSeats
      ShowtimeModel? showtime = await getShowtime(temp.showtimeId);
      if (showtime != null) {
        List<String> updatedSeats = List.from(showtime.availableSeats)..addAll(temp.seats);
        updatedSeats = updatedSeats.toSet().toList(); // Remove duplicates
        await updateShowtimeSeats(temp.showtimeId, updatedSeats);
      }
    }
    await _db.child('temp_bookings').child(tempId).remove();
  }

  //BOOKING
  Future<String> saveBooking(BookingModel booking) async {
    final ref = _db.child('bookings').push();
    await ref.set(booking.toMap());
    return ref.key!;
  }

  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    Query query = _db.child('bookings').orderByChild('userId').equalTo(userId);
    DataSnapshot snapshot = await query.get();
    List<BookingModel> bookings = [];
    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        bookings.add(BookingModel.fromMap(value, key));
      });
    }
    return bookings;
  }

  //PAYMENT
  Future<String> savePayment(PaymentModel payment) async {
    final ref = _db.child('payments').push();
    await ref.set(payment.toMap());
    return ref.key!;
  }

  //VOUCHER
  Future<VoucherModel?> getVoucher(String voucherId) async {
    DataSnapshot snapshot = await _db.child('vouchers').child(voucherId).get();
    if (snapshot.exists) {
      return VoucherModel.fromMap(snapshot.value as Map<dynamic, dynamic>, voucherId);
    }
    return null;
  }

  //THEATER
  Future<String> saveTheater(TheaterModel theater) async {
    final ref = _db.child('theaters').push(); // Generate ID
    await ref.set(theater.toMap());
    return ref.key!;
  }

  Future<TheaterModel?> getTheater(String theaterId) async {
    DataSnapshot snapshot = await _db.child('theaters').child(theaterId).get();
    if (snapshot.exists) {
      return TheaterModel.fromMap(snapshot.value as Map<dynamic, dynamic>, theaterId);
    }
    return null;
  }

  Future<List<TheaterModel>> getAllTheaters() async {
    DataSnapshot snapshot = await _db.child('theaters').get();
    List<TheaterModel> theaters = [];
    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        theaters.add(TheaterModel.fromMap(value, key));
      });
    }
    return theaters;
  }
}