import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Nếu cần UID từ Auth
import '../models/booking.dart'; // Import tất cả models
import '../models/movie.dart';
import '../models/showtime.dart';
import '../models/booking.dart';
import '../models/payment.dart';
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

  Future<void> updateMovie(String movieId, {double? newRating, String? newDescription}) async {
    Map<String, dynamic> updates = {};
    if (newRating != null) updates['rating'] = newRating;
    if (newDescription != null) updates['description'] = newDescription;
    await _db.child('movies').child(movieId).update(updates);
  }

  Future<void> deleteMovie(String movieId) async {
    await _db.child('movies').child(movieId).remove();
    // Optional: Xóa liên kết khác nếu cần, như showtimes liên quan
  }

//SHOWTIME
  Future<String> saveShowtime(ShowtimeModel showtime) async {
    final ref = _db.child('showtimes').push();
    await ref.set(showtime.toMap());
    return ref.key!;
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

  Future<void> reserveSeats(String showtimeId, List<String> seatsToReserve) async {
    final ref = _db.child('showtimes').child(showtimeId).child('availableSeats');
    await ref.runTransaction((currentData) {
      if (currentData == null) return Transaction.abort();
      List<dynamic> available = List.from(currentData as List<dynamic>);
      available.removeWhere((seat) => seatsToReserve.contains(seat));
      return Transaction.success(available);
    });
  }

  Future<void> updateShowtime(String showtimeId, {double? newPrice, int? newStartTime}) async {
    Map<String, dynamic> updates = {};
    if (newPrice != null) updates['price'] = newPrice;
    if (newStartTime != null) updates['startTime'] = newStartTime;
    await _db.child('showtimes').child(showtimeId).update(updates);
  }

  Future<void> deleteShowtime(String showtimeId) async {
    await _db.child('showtimes').child(showtimeId).remove();
  }

  //BookingModel và TempBookingModel
  Future<String> saveTempBooking(TempBookingModel temp) async {
    final ref = _db.child('temp_bookings').push();
    await ref.set(temp.toMap());
    // Đồng thời reserve seats trong Showtime
    await reserveSeats(temp.showtimeId, temp.seats);
    return ref.key!;
  }

  Future<String> convertTempToBooking(String tempId, double totalPrice, String? voucherId) async {
    TempBookingModel? temp = await getTempBooking(tempId);
    if (temp == null || temp.status != 'active') return '';

    // Tính finalPrice dựa trên voucher (logic ở đây hoặc trong BLoC)
    double finalPrice = totalPrice; // Áp voucher nếu có

    BookingModel booking = BookingModel(
      id: '', // Sẽ generate
      userId: temp.userId,
      showtimeId: temp.showtimeId,
      seats: temp.seats,
      totalPrice: totalPrice,
      finalPrice: finalPrice,
      voucherId: voucherId,
      status: 'confirmed',
    );

    final bookingRef = _db.child('bookings').push();
    await bookingRef.set(booking.toMap());

    // Cập nhật status temp và xóa nếu cần
    await _db.child('temp_bookings').child(tempId).update({'status': 'converted'});

    return bookingRef.key!;
  }

  Future<TempBookingModel?> getTempBooking(String tempId) async {
    DataSnapshot snapshot = await _db.child('temp_bookings').child(tempId).get();
    if (snapshot.exists) {
      return TempBookingModel.fromMap(snapshot.value as Map<dynamic, dynamic>, tempId);
    }
    return null;
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _db.child('bookings').child(bookingId).update({'status': newStatus});
  }

  Future<void> deleteBooking(String bookingId) async {
    await _db.child('bookings').child(bookingId).remove();
  }



  //PaymentModel và VoucherModel

  Future<String> savePayment(PaymentModel payment) async {
    final ref = _db.child('payments').push();
    await ref.set(payment.toMap());
    return ref.key!;
  }

  Future<VoucherModel?> getVoucher(String voucherId) async {
    DataSnapshot snapshot = await _db.child('vouchers').child(voucherId).get();
    if (snapshot.exists) {
      return VoucherModel.fromMap(snapshot.value as Map<dynamic, dynamic>, voucherId);
    }
    return null;
  }

  Future<void> updatePaymentStatus(String paymentId, String newStatus, String? transactionId) async {
    Map<String, dynamic> updates = {'status': newStatus};
    if (transactionId != null) updates['transactionId'] = transactionId;
    await _db.child('payments').child(paymentId).update(updates);
  }

  Future<void> deletePayment(String paymentId) async {
    await _db.child('payments').child(paymentId).remove();
  }

  Future<void> updateVoucher(String voucherId, {bool? isActive, int? newExpiryDate}) async {
    Map<String, dynamic> updates = {};
    if (isActive != null) updates['isActive'] = isActive;
    if (newExpiryDate != null) updates['expiryDate'] = newExpiryDate;
    await _db.child('vouchers').child(voucherId).update(updates);
  }

  Future<void> deleteVoucher(String voucherId) async {
    await _db.child('vouchers').child(voucherId).remove();
  }

  Future<void> updateTempBooking(String tempId, {int? newExpiryTime, String? newStatus}) async {
    Map<String, dynamic> updates = {};
    if (newExpiryTime != null) updates['expiryTime'] = newExpiryTime;
    if (newStatus != null) updates['status'] = newStatus;
    await _db.child('temp_bookings').child(tempId).update(updates);
  }

  Future<void> deleteTempBooking(String tempId) async {
    await _db.child('temp_bookings').child(tempId).remove();
    // Optional: Release seats trong Showtime nếu status là 'active'
  }
}

