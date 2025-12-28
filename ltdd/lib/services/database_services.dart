// File: lib/services/database_services.dart
// FINAL FIX - Xử lý hoàn toàn mọi trường hợp data lỗi

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import '../models/movie.dart';
import '../models/showtime.dart';
import '../models/payment.dart';
import '../models/theater.dart';
import '../models/cinema.dart';
import '../models/voucher.dart';
import '../models/tempbooking.dart';
import '../models/user.dart';
import '../models/movie_rating.dart';
import '../models/movie_comment.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // ✅ IMPROVED: Helper method to convert Map safely
  Map<dynamic, dynamic> _convertMap(dynamic data) {
    try {
      if (data == null) return {};
      if (data is String) {
        print('⚠️ Warning: _convertMap received String instead of Map');
        return {};
      }
      if (data is Map) {
        try {
          return Map<dynamic, dynamic>.from(data);
        } catch (e) {
          print('⚠️ Error converting Map in _convertMap: $e');
          return {};
        }
      }
      print('⚠️ Warning: Expected Map but got ${data.runtimeType}');
      return {};
    } catch (e) {
      print('⚠️ Error in _convertMap: $e');
      return {};
    }
  }

  // ✅ FIXED: Safe method to get query result with better error handling
  Future<Map<dynamic, dynamic>?> _safeQueryGet(Query query) async {
    try {
      DataSnapshot snapshot = await query.get();

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final value = snapshot.value;

      // If entire result is String or not Map, return null
      if (value is! Map) {
        print('⚠️ Query returned ${value.runtimeType} instead of Map, skipping');
        return null;
      }

      return Map<dynamic, dynamic>.from(value);
    } catch (e) {
      // Catch type conversion errors
      print('⚠️ Error in query (caught): $e');
      return null;
    }
  }

  //USER
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.child('users').child(user.id).set(user.toMap());
    } catch (e) {
      print('Error saving user: $e');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      DataSnapshot snapshot = await _db.child('users').child(userId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = _convertMap(snapshot.value);
        if (data.isNotEmpty) {
          return UserModel.fromMap(data, userId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
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
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = _convertMap(event.snapshot.value);
        if (data.isNotEmpty) {
          return UserModel.fromMap(data, _currentUserId!);
        }
      }
      return null;
    });
  }

  //MOVIE
  Future<String> saveMovie(MovieModel movie) async {
    final ref = _db.child('movies').push();
    await ref.set(movie.toMap());
    return ref.key!;
  }

  Future<void> updateMovie(MovieModel movie) async {
    await _db.child('movies').child(movie.id).update(movie.toMap());
  }

  Future<void> deleteMovie(String movieId) async {
    await _db.child('movies').child(movieId).remove();
  }

  Future<MovieModel?> getMovie(String movieId) async {
    try {
      DataSnapshot snapshot = await _db.child('movies').child(movieId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = _convertMap(snapshot.value);
        if (data.isNotEmpty) {
          return MovieModel.fromMap(data, movieId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting movie: $e');
      return null;
    }
  }

  Future<List<MovieModel>> getAllMovies() async {
    try {
      DataSnapshot snapshot = await _db.child('movies').get();
      List<MovieModel> movies = [];

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;

        if (value is Map) {
          try {
            Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
            data.forEach((key, itemValue) {
              try {
                if (itemValue is Map) {
                  final itemMap = Map<dynamic, dynamic>.from(itemValue);
                  movies.add(MovieModel.fromMap(itemMap, key.toString()));
                } else {
                  print('⚠️ Skipping invalid movie: $key (${itemValue.runtimeType})');
                }
              } catch (e) {
                print('⚠️ Error parsing movie $key: $e');
              }
            });
          } catch (e) {
            print('⚠️ Error converting snapshot.value to Map: $e');
          }
        } else {
          print('⚠️ getAllMovies: snapshot.value is not a Map, got ${value.runtimeType}');
        }
      }
      
      // Filter out expired movies (all showtimes have passed)
      try {
        movies = await _filterExpiredMovies(movies, null);
      } catch (e) {
        print('⚠️ Error filtering expired movies: $e');
        // Return movies without filtering if filter fails
      }
      
      return movies;
    } on FirebaseException catch (e) {
      // Xử lý lỗi permission denied
      if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc công khai movies');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
      }
      print('❌ Firebase error getting all movies: ${e.code} - ${e.message}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error getting all movies: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Get all movies for admin (including expired movies)
  // This method does NOT filter expired movies, so admin can see and manage all movies
  Future<List<MovieModel>> getAllMoviesForAdmin() async {
    try {
      DataSnapshot snapshot = await _db.child('movies').get();
      List<MovieModel> movies = [];

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;

        if (value is Map) {
          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
          data.forEach((key, itemValue) {
            try {
              if (itemValue is Map) {
                final itemMap = Map<dynamic, dynamic>.from(itemValue);
                movies.add(MovieModel.fromMap(itemMap, key.toString()));
              } else {
                print('⚠️ Skipping invalid movie: $key (${itemValue.runtimeType})');
              }
            } catch (e) {
              print('⚠️ Error parsing movie $key: $e');
            }
          });
        }
      }
      
      // Do NOT filter expired movies for admin - show all movies
      print('🎬 getAllMoviesForAdmin: Returning ${movies.length} movies (including expired)');
      
      return movies;
    } catch (e) {
      print('Error getting all movies for admin: $e');
      return [];
    }
  }

  //SHOWTIME
  Future<String> saveShowtime(ShowtimeModel showtime) async {
    final ref = _db.child('showtimes').push();
    await ref.set(showtime.toMap());
    return ref.key!;
  }

  Future<ShowtimeModel?> getShowtime(String showtimeId) async {
    try {
      DataSnapshot snapshot = await _db.child('showtimes').child(showtimeId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = _convertMap(snapshot.value);
        if (data.isNotEmpty) {
          return ShowtimeModel.fromMap(data, showtimeId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting showtime: $e');
      return null;
    }
  }

  // ✅ FINAL FIX: Completely safe query for showtimes with fallback
  Future<List<ShowtimeModel>> getShowtimesByMovie(String movieId) async {
    List<ShowtimeModel> showtimes = [];

    try {
      // Try using query first
      Query query = _db.child('showtimes').orderByChild('movieId').equalTo(movieId);

      // Use safer approach - catch at snapshot level
      DataSnapshot snapshot;
      try {
        snapshot = await query.get();
      } catch (e, stackTrace) {
        print('⚠️ Query snapshot error in getShowtimesByMovie: $e');
        print('Stack trace: $stackTrace');
        // Fallback: Load all showtimes and filter manually
        print('🔄 Falling back to manual filter method...');
        return await _getShowtimesByMovieFallback(movieId);
      }

      if (!snapshot.exists || snapshot.value == null) {
        print('ℹ️ No showtimes found for movie: $movieId');
        return showtimes;
      }

      // Wrap value processing in try-catch to handle any type conversion errors
      try {
        final value = snapshot.value;

        // Check if value is String (invalid data)
        if (value is String) {
          print('⚠️ Showtimes query returned String instead of Map, skipping');
          return showtimes;
        }

        // Check if value is Map
        if (value is! Map) {
          print('⚠️ Showtimes data is ${value.runtimeType}, expected Map. Skipping.');
          return showtimes;
        }

        // Process each item - wrap in try-catch for safe conversion
        Map<dynamic, dynamic> data;
        try {
          data = Map<dynamic, dynamic>.from(value);
        } catch (e) {
          print('⚠️ Error converting showtimes data to Map: $e');
          return showtimes;
        }

        data.forEach((key, itemValue) {
          try {
            // Skip if itemValue is null or String
            if (itemValue == null) {
              print('⚠️ Skipping null showtime: $key');
              return;
            }

            if (itemValue is String) {
              print('⚠️ Skipping invalid showtime (String): $key');
              return;
            }

            if (itemValue is! Map) {
              print('⚠️ Skipping invalid showtime type: $key (${itemValue.runtimeType})');
              return;
            }

            // Convert to Map and create ShowtimeModel - wrap in try-catch
            Map<dynamic, dynamic> itemMap;
            try {
              itemMap = Map<dynamic, dynamic>.from(itemValue);
            } catch (e) {
              print('⚠️ Error converting showtime $key to Map: $e');
              return;
            }

            try {
              showtimes.add(ShowtimeModel.fromMap(itemMap, key.toString()));
            } catch (e) {
              print('⚠️ Error creating ShowtimeModel for $key: $e');
            }

          } catch (e) {
            print('⚠️ Error parsing showtime $key: $e');
          }
        });

        print('✅ Loaded ${showtimes.length} showtimes for movie: $movieId');
      } catch (e) {
        print('⚠️ Error processing showtimes snapshot value: $e');
        // Return empty list instead of crashing
        return showtimes;
      }

    } catch (e) {
      print('❌ Error getting showtimes by movie: $e');
    }

    return showtimes;
  }

  // ✅ FALLBACK: Load all showtimes and filter manually when query fails
  Future<List<ShowtimeModel>> _getShowtimesByMovieFallback(String movieId) async {
    List<ShowtimeModel> showtimes = [];
    
    try {
      print('🔄 Loading all showtimes and filtering for movieId: $movieId');
      DataSnapshot snapshot = await _db.child('showtimes').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        print('ℹ️ No showtimes found in database');
        return showtimes;
      }

      final value = snapshot.value;

      // Check if value is String (invalid data)
      if (value is String) {
        print('⚠️ Showtimes node contains String instead of Map');
        return showtimes;
      }

      if (value is! Map) {
        print('⚠️ Showtimes data is ${value.runtimeType}, expected Map');
        return showtimes;
      }

      Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
      print('📊 Found ${data.length} total showtimes, filtering for movieId: $movieId');

      data.forEach((key, itemValue) {
        try {
          if (itemValue == null || itemValue is String) {
            return;
          }

          if (itemValue is! Map) {
            return;
          }

          Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
          
          // Filter by movieId
          final itemMovieId = itemMap['movieId']?.toString() ?? '';
          if (itemMovieId == movieId) {
            try {
              showtimes.add(ShowtimeModel.fromMap(itemMap, key.toString()));
            } catch (e) {
              print('⚠️ Error creating ShowtimeModel for $key: $e');
            }
          }
        } catch (e) {
          print('⚠️ Error parsing showtime $key: $e');
        }
      });

      print('✅ Loaded ${showtimes.length} showtimes for movie: $movieId (using fallback)');
    } catch (e) {
      print('❌ Error in fallback method: $e');
    }

    return showtimes;
  }

  Future<void> updateShowtimeSeats(String showtimeId, List<String> newAvailableSeats) async {
    await _db.child('showtimes').child(showtimeId).update({'availableSeats': newAvailableSeats});
  }

  Future<void> updateShowtime(ShowtimeModel showtime) async {
    await _db.child('showtimes').child(showtime.id).update(showtime.toMap());
  }

  Future<void> deleteShowtime(String showtimeId) async {
    await _db.child('showtimes').child(showtimeId).remove();
  }

  Future<List<ShowtimeModel>> getAllShowtimes() async {
    try {
      DataSnapshot snapshot = await _db.child('showtimes').get();
      List<ShowtimeModel> showtimes = [];

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;

        if (value is Map) {
          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
          data.forEach((key, itemValue) {
            try {
              if (itemValue is Map) {
                Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
                showtimes.add(ShowtimeModel.fromMap(itemMap, key.toString()));
              }
            } catch (e) {
              print('⚠️ Error parsing showtime $key: $e');
            }
          });
        }
      }
      return showtimes;
    } catch (e) {
      print('Error getting all showtimes: $e');
      return [];
    }
  }

  //TEMP BOOKING
  Future<String> saveTempBooking(TempBookingModel temp) async {
    final ref = _db.child('temp_bookings').push();
    await ref.set(temp.toMap());
    String tempId = ref.key!;

    ShowtimeModel? showtime = await getShowtime(temp.showtimeId);
    if (showtime != null) {
      List<String> updatedSeats = List.from(showtime.availableSeats)..removeWhere((seat) => temp.seats.contains(seat));
      await updateShowtimeSeats(temp.showtimeId, updatedSeats);
    }

    return tempId;
  }

  Future<TempBookingModel?> getTempBooking(String tempId) async {
    try {
      DataSnapshot snapshot = await _db.child('temp_bookings').child(tempId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = _convertMap(snapshot.value);
        if (data.isNotEmpty) {
          return TempBookingModel.fromMap(data, tempId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting temp booking: $e');
      return null;
    }
  }

  Future<void> deleteTempBooking(String tempId, {bool addBackSeats = true}) async {
    TempBookingModel? temp = await getTempBooking(tempId);
    if (temp != null && temp.status == 'active' && addBackSeats) {
      ShowtimeModel? showtime = await getShowtime(temp.showtimeId);
      if (showtime != null) {
        List<String> updatedSeats = List.from(showtime.availableSeats)..addAll(temp.seats);
        updatedSeats = updatedSeats.toSet().toList();
        await updateShowtimeSeats(temp.showtimeId, updatedSeats);
      }
    }
    await _db.child('temp_bookings').child(tempId).remove();
  }

  //BOOKING
  Future<String> saveBooking(BookingModel booking) async {
    try {
      final ref = _db.child('bookings').push();
      await ref.set(booking.toMap());
      return ref.key!;
    } on FirebaseException catch (e) {
      print('❌ Firebase error saving booking: ${e.code} - ${e.message}');
      if (e.code == 'PERMISSION_DENIED') {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép ghi bookings');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
      }
      rethrow;
    } catch (e) {
      print('❌ Error saving booking: $e');
      rethrow;
    }
  }

  // ✅ FINAL FIX: Safe query for bookings with fallback
  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    List<BookingModel> bookings = [];

    try {
      Query query = _db.child('bookings').orderByChild('userId').equalTo(userId);

      DataSnapshot snapshot;
      try {
        snapshot = await query.get();
      } on FirebaseException catch (e) {
        // Xử lý lỗi permission denied
        if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
          print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc bookings');
          print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
          // Vẫn thử fallback method
          return await _getBookingsByUserFallback(userId);
        }
        print('⚠️ Firebase error in query: ${e.code} - ${e.message}');
        return await _getBookingsByUserFallback(userId);
      } catch (e, stackTrace) {
        print('⚠️ Query snapshot error in getBookingsByUser: $e');
        print('Stack trace: $stackTrace');
        // Fallback: Load all bookings and filter manually
        print('🔄 Falling back to manual filter method...');
        return await _getBookingsByUserFallback(userId);
      }

      if (!snapshot.exists || snapshot.value == null) {
        return bookings;
      }

      // Wrap value processing in try-catch to handle any type conversion errors
      try {
        final value = snapshot.value;

        // Check if value is String (invalid data)
        if (value is String) {
          print('⚠️ Bookings query returned String instead of Map, skipping');
          return bookings;
        }

        if (value is! Map) {
          print('⚠️ Bookings data is ${value.runtimeType}, expected Map');
          return bookings;
        }

        // Safe conversion with try-catch
        Map<dynamic, dynamic> data;
        try {
          data = Map<dynamic, dynamic>.from(value);
        } catch (e) {
          print('⚠️ Error converting bookings data to Map: $e');
          return bookings;
        }

        data.forEach((key, itemValue) {
          try {
            // Skip if itemValue is null or String
            if (itemValue == null) {
              print('⚠️ Skipping null booking: $key');
              return;
            }
            
            if (itemValue is String) {
              print('⚠️ Skipping invalid booking (String): $key');
              return;
            }
            
            if (itemValue is! Map) {
              print('⚠️ Skipping invalid booking type: $key (${itemValue.runtimeType})');
              return;
            }

            // Safe conversion with try-catch
            Map<dynamic, dynamic> itemMap;
            try {
              itemMap = Map<dynamic, dynamic>.from(itemValue);
            } catch (e) {
              print('⚠️ Error converting booking $key to Map: $e');
              return;
            }

            try {
              bookings.add(BookingModel.fromMap(itemMap, key.toString()));
            } catch (e) {
              print('⚠️ Error creating BookingModel for $key: $e');
            }

          } catch (e) {
            print('⚠️ Error parsing booking $key: $e');
          }
        });
      } catch (e) {
        print('⚠️ Error processing bookings snapshot value: $e');
        // Return empty list instead of crashing
        return bookings;
      }

    } catch (e) {
      print('❌ Error getting bookings by user: $e');
    }

    return bookings;
  }

  // ✅ FALLBACK: Load all bookings and filter manually when query fails
  Future<List<BookingModel>> _getBookingsByUserFallback(String userId) async {
    List<BookingModel> bookings = [];
    
    try {
      print('🔄 Loading all bookings and filtering for userId: $userId');
      DataSnapshot snapshot = await _db.child('bookings').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        print('ℹ️ No bookings found in database');
        return bookings;
      }

      final value = snapshot.value;

      if (value is String) {
        print('⚠️ Bookings node contains String instead of Map');
        return bookings;
      }

      if (value is! Map) {
        print('⚠️ Bookings data is ${value.runtimeType}, expected Map');
        return bookings;
      }

      try {
        Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
        print('📊 Found ${data.length} total bookings, filtering for userId: $userId');

        data.forEach((key, itemValue) {
          try {
            if (itemValue == null || itemValue is String) {
              return;
            }

            if (itemValue is! Map) {
              return;
            }

            Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
            
            // Filter by userId
            final itemUserId = itemMap['userId']?.toString() ?? '';
            if (itemUserId == userId) {
              try {
                bookings.add(BookingModel.fromMap(itemMap, key.toString()));
              } catch (e) {
                print('⚠️ Error creating BookingModel for $key: $e');
              }
            }
          } catch (e) {
            print('⚠️ Error parsing booking $key: $e');
          }
        });

        print('✅ Loaded ${bookings.length} bookings for user: $userId (using fallback)');
      } catch (e) {
        print('⚠️ Error converting bookings data to Map: $e');
      }
    } on FirebaseException catch (e) {
      // Xử lý lỗi permission denied
      if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc bookings');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
      }
      print('❌ Firebase error in fallback method: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Error in fallback method: $e');
      print('Stack trace: $stackTrace');
    }

    return bookings;
  }

  //PAYMENT
  Future<String> savePayment(PaymentModel payment) async {
    try {
      final ref = _db.child('payments').push();
      await ref.set(payment.toMap());
      return ref.key!;
    } on FirebaseException catch (e) {
      print('❌ Firebase error saving payment: ${e.code} - ${e.message}');
      if (e.code == 'PERMISSION_DENIED') {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép ghi payments');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
      }
      rethrow;
    } catch (e) {
      print('❌ Error saving payment: $e');
      rethrow;
    }
  }

  //VOUCHER
  Future<VoucherModel?> getVoucher(String voucherId) async {
    try {
      DataSnapshot snapshot = await _db.child('vouchers').child(voucherId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = _convertMap(snapshot.value);
        if (data.isNotEmpty) {
          return VoucherModel.fromMap(data, voucherId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting voucher: $e');
      return null;
    }
  }

  Future<List<VoucherModel>> getAllVouchers() async {
    try {
      DataSnapshot snapshot = await _db.child('vouchers').get();
      List<VoucherModel> vouchers = [];

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;

        if (value is Map) {
          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
          data.forEach((key, itemValue) {
            try {
              if (itemValue is Map) {
                Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
                vouchers.add(VoucherModel.fromMap(itemMap, key.toString()));
              }
            } catch (e) {
              print('⚠️ Error parsing voucher $key: $e');
            }
          });
        }
      }
      return vouchers;
    } catch (e) {
      print('Error getting all vouchers: $e');
      return [];
    }
  }

  Future<void> saveVoucher(VoucherModel voucher) async {
    try {
      await _db.child('vouchers').child(voucher.id).set(voucher.toMap());
    } catch (e) {
      print('Error saving voucher: $e');
      rethrow;
    }
  }

  Future<void> updateVoucher(VoucherModel voucher) async {
    try {
      await _db.child('vouchers').child(voucher.id).update(voucher.toMap());
    } catch (e) {
      print('Error updating voucher: $e');
      rethrow;
    }
  }

  Future<void> deleteVoucher(String voucherId) async {
    try {
      await _db.child('vouchers').child(voucherId).remove();
    } catch (e) {
      print('Error deleting voucher: $e');
      rethrow;
    }
  }

  //CINEMA
  Future<String> saveCinema(CinemaModel cinema) async {
    final ref = _db.child('cinemas').push();
    await ref.set(cinema.toMap());
    return ref.key!;
  }

  Future<void> updateCinema(CinemaModel cinema) async {
    try {
      await _db.child('cinemas').child(cinema.id).update(cinema.toMap());
    } catch (e) {
      print('Error updating cinema: $e');
      rethrow;
    }
  }

  Future<void> deleteCinema(String cinemaId) async {
    try {
      await _db.child('cinemas').child(cinemaId).remove();
    } catch (e) {
      print('Error deleting cinema: $e');
      rethrow;
    }
  }

  Future<CinemaModel?> getCinema(String cinemaId) async {
    try {
      DataSnapshot snapshot = await _db.child('cinemas').child(cinemaId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = _convertMap(snapshot.value);
        if (data.isNotEmpty) {
          return CinemaModel.fromMap(data, cinemaId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting cinema: $e');
      return null;
    }
  }

  Future<List<CinemaModel>> getAllCinemas() async {
    try {
      DataSnapshot snapshot = await _db.child('cinemas').get();
      List<CinemaModel> cinemas = [];
      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;
        
        // Kiểm tra nếu value là Map
        if (value is Map) {
          try {
            Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
            data.forEach((key, itemValue) {
              try {
                // Chỉ parse nếu itemValue là Map, bỏ qua nếu là String hoặc type khác
                if (itemValue is Map) {
                  cinemas.add(CinemaModel.fromMap(Map<dynamic, dynamic>.from(itemValue), key.toString()));
                } else {
                  print('⚠️ Skipping invalid cinema: $key (${itemValue.runtimeType})');
                }
              } catch (e) {
                print('⚠️ Error parsing cinema $key: $e');
              }
            });
          } catch (e) {
            print('⚠️ Error converting snapshot.value to Map: $e');
          }
        } else {
          print('⚠️ getAllCinemas: snapshot.value is not a Map, got ${value.runtimeType}');
        }
      }
      return cinemas;
    } on FirebaseException catch (e) {
      // Xử lý lỗi permission denied
      if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc công khai cinemas');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
      }
      print('❌ Firebase error getting all cinemas: ${e.code} - ${e.message}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error getting all cinemas: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  //THEATER
  Future<String> saveTheater(TheaterModel theater) async {
    final ref = _db.child('theaters').push();
    await ref.set(theater.toMap());
    return ref.key!;
  }

  Future<TheaterModel?> getTheater(String theaterId) async {
    try {
      DataSnapshot snapshot = await _db.child('theaters').child(theaterId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = _convertMap(snapshot.value);
        if (data.isNotEmpty) {
          return TheaterModel.fromMap(data, theaterId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting theater: $e');
      return null;
    }
  }

  Future<List<TheaterModel>> getAllTheaters() async {
    try {
      DataSnapshot snapshot = await _db.child('theaters').get();
      List<TheaterModel> theaters = [];

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;

        if (value is Map) {
          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
          data.forEach((key, itemValue) {
            try {
              if (itemValue is Map) {
                Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
                theaters.add(TheaterModel.fromMap(itemMap, key.toString()));
              }
            } catch (e) {
              print('⚠️ Error parsing theater $key: $e');
            }
          });
        }
      }
      return theaters;
    } catch (e) {
      print('Error getting all theaters: $e');
      return [];
    }
  }

  Future<void> updateTheater(TheaterModel theater) async {
    await _db.child('theaters').child(theater.id).update(theater.toMap());
  }

  Future<void> deleteTheater(String theaterId) async {
    await _db.child('theaters').child(theaterId).remove();
  }

  Future<List<TheaterModel>> getTheatersByCinema(String cinemaId) async {
    try {
      DataSnapshot snapshot = await _db.child('theaters').get();
      List<TheaterModel> theaters = [];

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;

        if (value is Map) {
          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
          data.forEach((key, itemValue) {
            try {
              if (itemValue is Map) {
                Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
                final theaterCinemaId = itemMap['cinemaId']?.toString() ?? '';
                if (theaterCinemaId == cinemaId) {
                  theaters.add(TheaterModel.fromMap(itemMap, key.toString()));
                }
              }
            } catch (e) {
              print('⚠️ Error parsing theater $key: $e');
            }
          });
        }
      }
      return theaters;
    } catch (e) {
      print('Error getting theaters by cinema: $e');
      return [];
    }
  }

  // Get movies by cinemaId for admin (including expired movies)
  // This method does NOT filter expired movies, so admin can see and manage all movies
  Future<List<MovieModel>> getMoviesByCinemaForAdmin(String cinemaId) async {
    try {
      print('🎬 getMoviesByCinemaForAdmin: Loading movies for cinema $cinemaId (including expired)');
      DataSnapshot snapshot = await _db.child('movies').get();
      List<MovieModel> movies = [];
      if (snapshot.exists && snapshot.value != null) {
        final data = _convertMap(snapshot.value);
        int totalMovies = 0;
        data.forEach((key, value) {
          try {
            if (value is Map) {
              totalMovies++;
              Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(value);
              final movieCinemaId = itemMap['cinemaId']?.toString() ?? '';
              if (movieCinemaId == cinemaId) {
                movies.add(MovieModel.fromMap(itemMap, key.toString()));
                print('🎬   - Found movie: ${itemMap['title']} (ID: $key, cinemaId: $movieCinemaId)');
              }
            }
          } catch (e) {
            print('⚠️ Error parsing movie $key: $e');
          }
        });
        print('🎬 getMoviesByCinemaForAdmin: Checked $totalMovies movies, found ${movies.length} for cinema $cinemaId (including expired)');
      } else {
        print('🎬 getMoviesByCinemaForAdmin: No movies found in database');
      }
      
      // Do NOT filter expired movies for admin - show all movies
      return movies;
    } catch (e) {
      print('Error getting movies by cinema for admin: $e');
      return [];
    }
  }

  // Get movies by cinemaId (movies belong to a specific cinema)
  Future<List<MovieModel>> getMoviesByCinema(String cinemaId) async {
    try {
      print('🎬 getMoviesByCinema: Loading movies for cinema $cinemaId');
      DataSnapshot snapshot = await _db.child('movies').get();
      List<MovieModel> movies = [];
      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;
        Map<dynamic, dynamic> data = {};
        
        // Kiểm tra nếu value là Map
        if (value is Map) {
          data = Map<dynamic, dynamic>.from(value);
        } else {
          print('⚠️ getMoviesByCinema: snapshot.value is not a Map, got ${value.runtimeType}');
        }
        
        int totalMovies = 0;
        data.forEach((key, itemValue) {
          try {
            if (itemValue is Map) {
              totalMovies++;
              Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
              final movieCinemaId = itemMap['cinemaId']?.toString() ?? '';
              if (movieCinemaId == cinemaId) {
                movies.add(MovieModel.fromMap(itemMap, key.toString()));
                print('🎬   - Found movie: ${itemMap['title']} (ID: $key, cinemaId: $movieCinemaId)');
              }
            } else {
              print('⚠️ Skipping invalid movie: $key (${itemValue.runtimeType})');
            }
          } catch (e) {
            print('⚠️ Error parsing movie $key: $e');
          }
        });
        print('🎬 getMoviesByCinema: Checked $totalMovies movies, found ${movies.length} for cinema $cinemaId');
      } else {
        print('🎬 getMoviesByCinema: No movies found in database');
      }
      
      // Filter out expired movies (all showtimes have passed)
      movies = await _filterExpiredMovies(movies, cinemaId);
      
      return movies;
    } catch (e) {
      print('Error getting movies by cinema: $e');
      return [];
    }
  }

  // Get showtimes by movie and cinema
  Future<List<ShowtimeModel>> getShowtimesByMovieAndCinema(String movieId, String cinemaId) async {
    try {
      // Get all theaters of this cinema
      List<TheaterModel> theaters = await getTheatersByCinema(cinemaId);
      List<String> theaterIds = theaters.map((t) => t.id).toList();

      // Get showtimes
      List<ShowtimeModel> showtimes = await getShowtimesByMovie(movieId);
      return showtimes.where((showtime) => theaterIds.contains(showtime.theaterId)).toList();
    } catch (e) {
      print('Error getting showtimes by movie and cinema: $e');
      return [];
    }
  }

  // Get movies that have showtimes today (filter by cinema if specified)
  Future<List<MovieModel>> getMoviesShowingToday({String? cinemaId}) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day); // 00:00:00 hôm nay
      final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); // 23:59:59 hôm nay
      final todayStartMillis = todayStart.millisecondsSinceEpoch;
      final todayEndMillis = todayEnd.millisecondsSinceEpoch;

      // Get theaters of this cinema if cinemaId is specified
      Set<String> theaterIds = {};
      if (cinemaId != null && cinemaId.isNotEmpty) {
        List<TheaterModel> theaters = await getTheatersByCinema(cinemaId);
        theaterIds = theaters.map((t) => t.id).toSet();
        print('🎬 getMoviesShowingToday: Found ${theaters.length} theaters for cinema $cinemaId');
        print('🎬 Theater IDs: $theaterIds');
        // If cinema has no theaters, return empty list (no movies can have showtimes)
        if (theaterIds.isEmpty) {
          print('⚠️ Warning: Cinema $cinemaId has no theaters! Returning empty list.');
          return [];
        }
      }

      // Get all showtimes
      DataSnapshot showtimesSnapshot = await _db.child('showtimes').get();
      Set<String> movieIds = {};

      if (showtimesSnapshot.exists && showtimesSnapshot.value != null) {
        final showtimesValue = showtimesSnapshot.value;
        Map<dynamic, dynamic> showtimesData = {};
        
        // Kiểm tra nếu value là Map
        if (showtimesValue is Map) {
          showtimesData = Map<dynamic, dynamic>.from(showtimesValue);
        } else {
          print('⚠️ getMoviesShowingToday: showtimesSnapshot.value is not a Map, got ${showtimesValue.runtimeType}');
        }
        
        int showtimesChecked = 0;
        int showtimesMatched = 0;
        
        showtimesData.forEach((key, value) {
          try {
            if (value is Map) {
              final showtimeMap = Map<dynamic, dynamic>.from(value);
              final startTime = showtimeMap['startTime'];
              final movieId = showtimeMap['movieId']?.toString();
              final theaterId = showtimeMap['theaterId']?.toString();
              
              // If cinemaId is specified, only include showtimes from theaters of that cinema
              if (cinemaId != null && cinemaId.isNotEmpty) {
                if (theaterId == null || !theaterIds.contains(theaterId)) {
                  return; // Skip this showtime
                }
              }
              
              if (movieId != null && startTime != null) {
                showtimesChecked++;
                int startTimeMillis = 0;
                if (startTime is num) {
                  startTimeMillis = startTime.toInt();
                } else if (startTime is String) {
                  startTimeMillis = int.tryParse(startTime) ?? 0;
                }

                // Check if showtime is today
                if (startTimeMillis >= todayStartMillis && startTimeMillis <= todayEndMillis) {
                  movieIds.add(movieId);
                  showtimesMatched++;
                }
              }
            }
          } catch (e) {
            print('⚠️ Error parsing showtime $key: $e');
          }
        });
        
        print('🎬 getMoviesShowingToday: Checked $showtimesChecked showtimes, matched $showtimesMatched for today');
        print('🎬 Found ${movieIds.length} unique movieIds: $movieIds');
      }

      // Load movies for these movieIds
      // Note: We don't filter by movie.cinemaId here because we already filtered by theaterId
      // A movie can have showtimes in multiple cinemas, so we trust the theaterId filter
      List<MovieModel> movies = [];
      if (movieIds.isNotEmpty) {
        DataSnapshot moviesSnapshot = await _db.child('movies').get();
        if (moviesSnapshot.exists && moviesSnapshot.value != null) {
          final moviesValue = moviesSnapshot.value;
          Map<dynamic, dynamic> moviesData = {};
          
          // Kiểm tra nếu value là Map
          if (moviesValue is Map) {
            moviesData = Map<dynamic, dynamic>.from(moviesValue);
          } else {
            print('⚠️ getMoviesShowingToday: moviesSnapshot.value is not a Map, got ${moviesValue.runtimeType}');
          }
          
          moviesData.forEach((key, value) {
            try {
              if (value is Map && movieIds.contains(key.toString())) {
                final movieMap = Map<dynamic, dynamic>.from(value);
                // If cinemaId is specified, we already filtered by theaterId, so just add the movie
                // If cinemaId is null, add all movies that have showtimes today
                movies.add(MovieModel.fromMap(movieMap, key.toString()));
              } else if (value is! Map) {
                print('⚠️ Skipping invalid movie: $key (${value.runtimeType})');
              }
            } catch (e) {
              print('⚠️ Error parsing movie $key: $e');
            }
          });
        }
      }

      // Filter out expired movies (all showtimes have passed)
      movies = await _filterExpiredMovies(movies, cinemaId);
      
      print('🎬 getMoviesShowingToday: Returning ${movies.length} movies for cinema ${cinemaId ?? "all"}');
      
      // Only return movies with showtimes today - no fallback
      // Movies without showtimes or with showtimes not today will be in "coming soon"
      return movies;
    } on FirebaseException catch (e) {
      // Xử lý lỗi permission denied
      if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc công khai showtimes');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
      }
      print('❌ Firebase error getting movies showing today: ${e.code} - ${e.message}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error getting movies showing today: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Get movies that have showtimes from tomorrow onwards OR no showtimes at all (filter by cinema if specified)
  Future<List<MovieModel>> getMoviesComingSoon({String? cinemaId}) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day); // 00:00:00 hôm nay
      final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); // 23:59:59 hôm nay
      final tomorrowStart = todayStart.add(const Duration(days: 1)); // 00:00:00 ngày mai
      final todayStartMillis = todayStart.millisecondsSinceEpoch;
      final todayEndMillis = todayEnd.millisecondsSinceEpoch;
      final tomorrowStartMillis = tomorrowStart.millisecondsSinceEpoch;

      // Get all movies of this cinema first
      List<MovieModel> allCinemaMovies = [];
      if (cinemaId != null && cinemaId.isNotEmpty) {
        allCinemaMovies = await getMoviesByCinema(cinemaId);
      } else {
        allCinemaMovies = await getAllMovies();
      }

      // Get theaters of this cinema if cinemaId is specified
      Set<String> theaterIds = {};
      if (cinemaId != null && cinemaId.isNotEmpty) {
        List<TheaterModel> theaters = await getTheatersByCinema(cinemaId);
        theaterIds = theaters.map((t) => t.id).toSet();
      }

      // Get all showtimes to find which movies have showtimes
      DataSnapshot showtimesSnapshot = await _db.child('showtimes').get();
      Set<String> moviesWithShowtimesToday = {}; // Movies with showtimes today
      Set<String> moviesWithShowtimesFuture = {}; // Movies with showtimes from tomorrow onwards
      Set<String> allMoviesWithShowtimes = {}; // All movies that have any showtimes

      if (showtimesSnapshot.exists && showtimesSnapshot.value != null) {
        final showtimesValue = showtimesSnapshot.value;
        Map<dynamic, dynamic> showtimesData = {};
        
        // Kiểm tra nếu value là Map
        if (showtimesValue is Map) {
          showtimesData = Map<dynamic, dynamic>.from(showtimesValue);
        } else {
          print('⚠️ getMoviesComingSoon: showtimesSnapshot.value is not a Map, got ${showtimesValue.runtimeType}');
        }
        
        showtimesData.forEach((key, value) {
          try {
            if (value is Map) {
              final showtimeMap = Map<dynamic, dynamic>.from(value);
              final startTime = showtimeMap['startTime'];
              final movieId = showtimeMap['movieId']?.toString();
              final theaterId = showtimeMap['theaterId']?.toString();
              
              // If cinemaId is specified, only include showtimes from theaters of that cinema
              if (cinemaId != null && cinemaId.isNotEmpty) {
                if (theaterId == null || !theaterIds.contains(theaterId)) {
                  return; // Skip this showtime
                }
              }
              
              if (movieId != null && startTime != null) {
                int startTimeMillis = 0;
                if (startTime is num) {
                  startTimeMillis = startTime.toInt();
                } else if (startTime is String) {
                  startTimeMillis = int.tryParse(startTime) ?? 0;
                }

                allMoviesWithShowtimes.add(movieId);

                // Check if showtime is today
                if (startTimeMillis >= todayStartMillis && startTimeMillis <= todayEndMillis) {
                  moviesWithShowtimesToday.add(movieId);
                }
                // Check if showtime is from tomorrow onwards
                else if (startTimeMillis >= tomorrowStartMillis) {
                  moviesWithShowtimesFuture.add(movieId);
                }
              }
            }
          } catch (e) {
            print('⚠️ Error parsing showtime $key: $e');
          }
        });
      }

      // Filter movies: All movies of cinema EXCEPT those with showtimes today
      // This includes:
      // 1. Movies with no showtimes at all
      // 2. Movies with showtimes from tomorrow onwards
      // 3. Movies with showtimes but not today (past showtimes)
      List<MovieModel> movies = [];
      for (var movie in allCinemaMovies) {
        // If movie has showtimes today, skip it (it's in "now showing")
        if (!moviesWithShowtimesToday.contains(movie.id)) {
          movies.add(movie);
        }
      }

      // Filter out expired movies (all showtimes have passed)
      movies = await _filterExpiredMovies(movies, cinemaId);
      
      print('🎬 getMoviesComingSoon: Returning ${movies.length} movies for cinema ${cinemaId ?? "all"}');
      print('🎬   - Movies with showtimes today: ${moviesWithShowtimesToday.length} (excluded)');
      print('🎬   - Movies with showtimes future: ${moviesWithShowtimesFuture.length}');
      print('🎬   - Movies with no showtimes: ${allCinemaMovies.length - allMoviesWithShowtimes.length}');

      return movies;
    } on FirebaseException catch (e) {
      // Xử lý lỗi permission denied
      if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc công khai');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
      }
      print('❌ Firebase error getting movies coming soon: ${e.code} - ${e.message}');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error getting movies coming soon: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Helper method to filter out expired movies (all showtimes have passed)
  // A movie is expired if it has showtimes but ALL of them are in the past
  Future<List<MovieModel>> _filterExpiredMovies(List<MovieModel> movies, String? cinemaId) async {
    if (movies.isEmpty) return movies;
    
    try {
      final now = DateTime.now();
      final nowMillis = now.millisecondsSinceEpoch;
      
      // Get theaters of this cinema if cinemaId is specified
      Set<String> theaterIds = {};
      if (cinemaId != null && cinemaId.isNotEmpty) {
        List<TheaterModel> theaters = await getTheatersByCinema(cinemaId);
        theaterIds = theaters.map((t) => t.id).toSet();
      }
      
      // Get all showtimes
      DataSnapshot showtimesSnapshot = await _db.child('showtimes').get();
      Map<String, List<int>> movieShowtimes = {}; // movieId -> list of startTime
      
      if (showtimesSnapshot.exists && showtimesSnapshot.value != null) {
        final showtimesValue = showtimesSnapshot.value;
        Map<dynamic, dynamic> showtimesData = {};
        
        // Kiểm tra nếu value là Map
        if (showtimesValue is Map) {
          showtimesData = Map<dynamic, dynamic>.from(showtimesValue);
        } else {
          print('⚠️ _filterExpiredMovies: showtimesSnapshot.value is not a Map, got ${showtimesValue.runtimeType}');
        }
        
        showtimesData.forEach((key, value) {
          try {
            if (value is Map) {
              final showtimeMap = Map<dynamic, dynamic>.from(value);
              final startTime = showtimeMap['startTime'];
              final movieId = showtimeMap['movieId']?.toString();
              final theaterId = showtimeMap['theaterId']?.toString();
              
              // If cinemaId is specified, only include showtimes from theaters of that cinema
              if (cinemaId != null && cinemaId.isNotEmpty) {
                if (theaterId == null || !theaterIds.contains(theaterId)) {
                  return; // Skip this showtime
                }
              }
              
              if (movieId != null && startTime != null) {
                int startTimeMillis = 0;
                if (startTime is num) {
                  startTimeMillis = startTime.toInt();
                } else if (startTime is String) {
                  startTimeMillis = int.tryParse(startTime) ?? 0;
                }
                
                if (!movieShowtimes.containsKey(movieId)) {
                  movieShowtimes[movieId] = [];
                }
                movieShowtimes[movieId]!.add(startTimeMillis);
              }
            }
          } catch (e) {
            print('⚠️ Error parsing showtime in _filterExpiredMovies: $e');
          }
        });
      }
      
      // Filter movies: Remove movies that have showtimes but ALL are expired
      List<MovieModel> filteredMovies = [];
      int expiredCount = 0;
      
      for (var movie in movies) {
        final movieShowtimesList = movieShowtimes[movie.id] ?? [];
        
        if (movieShowtimesList.isEmpty) {
          // Movie has no showtimes - not expired, keep it
          filteredMovies.add(movie);
        } else {
          // Movie has showtimes - check if ALL are expired
          final hasFutureShowtime = movieShowtimesList.any((startTime) => startTime >= nowMillis);
          
          if (hasFutureShowtime) {
            // Has at least one future showtime - not expired, keep it
            filteredMovies.add(movie);
          } else {
            // All showtimes are expired - remove it
            expiredCount++;
            print('🗑️ Filtering out expired movie: ${movie.title} (all showtimes have passed)');
          }
        }
      }
      
      if (expiredCount > 0) {
        print('🎬 _filterExpiredMovies: Filtered out $expiredCount expired movies');
      }
      
      return filteredMovies;
    } catch (e) {
      print('❌ Error in _filterExpiredMovies: $e');
      // Return original list if error occurs
      return movies;
    }
  }

  //NOTIFICATION
  Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? bookingId,
  }) async {
    try {
      final ref = _db.child('notifications').push();
      await ref.set({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': ServerValue.timestamp,
      });
      return ref.key!;
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // ✅ FINAL FIX: Safe query for notifications
  Future<List<dynamic>> getNotificationsByUser(String userId) async {
    List<dynamic> notifications = [];

    try {
      Query query = _db.child('notifications').orderByChild('userId').equalTo(userId);

      DataSnapshot snapshot;
      try {
        snapshot = await query.get();
      } on FirebaseException catch (e) {
        // Xử lý lỗi permission denied
        if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
          print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc notifications');
          print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
        }
        print('⚠️ Firebase error in query: ${e.code} - ${e.message}');
        return notifications;
      } catch (e, stackTrace) {
        print('⚠️ Query snapshot error in getNotificationsByUser: $e');
        print('Stack trace: $stackTrace');
        return notifications;
      }

      if (!snapshot.exists || snapshot.value == null) {
        return notifications;
      }

      // Wrap value processing in try-catch to handle any type conversion errors
      try {
        final value = snapshot.value;

        // Check if value is String (invalid data)
        if (value is String) {
          print('⚠️ Notifications query returned String instead of Map, skipping');
          return notifications;
        }

        if (value is! Map) {
          print('⚠️ Notifications data is ${value.runtimeType}, expected Map');
          return notifications;
        }

        // Safe conversion with try-catch
        Map<dynamic, dynamic> data;
        try {
          data = Map<dynamic, dynamic>.from(value);
        } catch (e) {
          print('⚠️ Error converting notifications data to Map: $e');
          return notifications;
        }

        data.forEach((key, itemValue) {
          try {
            // Skip if itemValue is null or String
            if (itemValue == null) {
              print('⚠️ Skipping null notification: $key');
              return;
            }
            
            if (itemValue is String) {
              print('⚠️ Skipping invalid notification (String): $key');
              return;
            }
            
            if (itemValue is! Map) {
              print('⚠️ Skipping invalid notification type: $key (${itemValue.runtimeType})');
              return;
            }

            // Safe conversion with try-catch
            Map<dynamic, dynamic> itemMap;
            try {
              itemMap = Map<dynamic, dynamic>.from(itemValue);
            } catch (e) {
              print('⚠️ Error converting notification $key to Map: $e');
              return;
            }

            try {
              notifications.add({
                'id': key.toString(),
                'userId': itemMap['userId']?.toString() ?? '',
                'title': itemMap['title']?.toString() ?? '',
                'message': itemMap['message']?.toString() ?? '',
                'type': itemMap['type']?.toString() ?? 'system',
                'bookingId': itemMap['bookingId']?.toString(),
                'isRead': itemMap['isRead'] as bool? ?? false,
                'createdAt': (itemMap['createdAt'] as num?)?.toInt() ?? 0,
              });
            } catch (e) {
              print('⚠️ Error creating notification data for $key: $e');
            }

          } catch (e) {
            print('⚠️ Error parsing notification $key: $e');
          }
        });
      } catch (e) {
        print('⚠️ Error processing notifications snapshot value: $e');
        // Return empty list instead of crashing
        return notifications;
      }

      // Sort by createdAt descending
      notifications.sort((a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));

    } catch (e) {
      print('❌ Error getting notifications by user: $e');
    }

    return notifications;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _db.child('notifications').child(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.child('notifications').child(notificationId).remove();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  //USER UPDATE
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _db.child('users').child(userId).update(updates);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  //SYNC SEATS
  Future<void> syncShowtimeSeats(String showtimeId) async {
    try {
      ShowtimeModel? showtime = await getShowtime(showtimeId);
      if (showtime == null) return;

      TheaterModel? theater = await getTheater(showtime.theaterId);
      if (theater == null) return;

      Query query = _db.child('bookings').orderByChild('showtimeId').equalTo(showtimeId);

      Set<String> bookedSeats = {};

      try {
        DataSnapshot snapshot = await query.get();

        if (snapshot.exists && snapshot.value != null) {
          final value = snapshot.value;
          
          // Check if value is String (invalid data)
          if (value is String) {
            print('⚠️ Sync query returned String instead of Map, skipping');
          } else if (value is Map) {
            Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);

            data.forEach((key, itemValue) {
              try {
                // Skip if itemValue is null or String
                if (itemValue == null || itemValue is String) {
                  return;
                }
                
                if (itemValue is Map) {
                  Map<dynamic, dynamic> booking = Map<dynamic, dynamic>.from(itemValue);
                  final status = booking['status']?.toString() ?? '';
                  if (status == 'confirmed' || status == 'pending') {
                    final seats = booking['seats'];
                    if (seats is List) {
                      bookedSeats.addAll(seats.map((s) => s.toString()));
                    }
                  }
                }
              } catch (e) {
                print('⚠️ Error processing booking in sync: $e');
              }
            });
          }
        }
      } catch (e) {
        print('⚠️ Error in sync query: $e');
      }

      List<String> availableSeats = theater.seats
          .where((seat) => !bookedSeats.contains(seat))
          .toList();

      await updateShowtimeSeats(showtimeId, availableSeats);

      print('✅ Synced seats for showtime $showtimeId: ${availableSeats.length} available');
    } catch (e) {
      print('Error syncing showtime seats: $e');
    }
  }

  //DELETE BOOKING WITH SYNC
  Future<void> deleteBooking(String bookingId) async {
    try {
      BookingModel? booking = await getBooking(bookingId);
      await _db.child('bookings').child(bookingId).remove();
      if (booking != null) {
        await syncShowtimeSeats(booking.showtimeId);
      }
    } catch (e) {
      print('Error deleting booking: $e');
    }
  }

  Future<BookingModel?> getBooking(String bookingId) async {
    try {
      DataSnapshot snapshot = await _db.child('bookings').child(bookingId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = _convertMap(snapshot.value);
        if (data.isNotEmpty) {
          return BookingModel.fromMap(data, bookingId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  // Get booking count by movieId (for popular movies)
  Future<Map<String, int>> getBookingCountsByMovie() async {
    Map<String, int> movieBookingCounts = {};
    
    try {
      // Load all bookings
      DataSnapshot bookingsSnapshot = await _db.child('bookings').get();
      if (!bookingsSnapshot.exists || bookingsSnapshot.value == null) {
        return movieBookingCounts;
      }

      // Load all showtimes to create map showtimeId -> movieId
      DataSnapshot showtimesSnapshot = await _db.child('showtimes').get();
      Map<String, String> showtimeToMovie = {};
      
      if (showtimesSnapshot.exists && showtimesSnapshot.value != null) {
        final showtimesData = _convertMap(showtimesSnapshot.value);
        showtimesData.forEach((key, value) {
          if (value is Map) {
            final showtimeMap = Map<dynamic, dynamic>.from(value);
            final movieId = showtimeMap['movieId']?.toString();
            if (movieId != null) {
              showtimeToMovie[key.toString()] = movieId;
            }
          }
        });
      }

      // Count bookings by movieId
      final bookingsData = _convertMap(bookingsSnapshot.value);
      bookingsData.forEach((key, value) {
        if (value is Map) {
          final bookingMap = Map<dynamic, dynamic>.from(value);
          final showtimeId = bookingMap['showtimeId']?.toString();
          final status = bookingMap['status']?.toString();
          
          // Only count confirmed bookings
          if (showtimeId != null && status == 'confirmed') {
            final movieId = showtimeToMovie[showtimeId];
            if (movieId != null) {
              movieBookingCounts[movieId] = (movieBookingCounts[movieId] ?? 0) + 1;
            }
          }
        }
      });
    } catch (e) {
      print('Error getting booking counts by movie: $e');
    }
    
    return movieBookingCounts;
  }

  Stream<ShowtimeModel?> listenToShowtime(String showtimeId) {
    return _db.child('showtimes').child(showtimeId).onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          final data = _convertMap(event.snapshot.value);
          if (data.isNotEmpty) {
            return ShowtimeModel.fromMap(data, showtimeId);
          }
        } catch (e) {
          print('Error parsing showtime stream: $e');
        }
      }
      return null;
    });
  }

  Stream<List<BookingModel>> listenToUserBookings(String userId) {
    return _db
        .child('bookings')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      List<BookingModel> bookings = [];
      try {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final value = event.snapshot.value;
          
          // Check if value is String (invalid data)
          if (value is String) {
            print('⚠️ Bookings stream returned String instead of Map, skipping');
            return bookings;
          }
          
          if (value is Map) {
            Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
            data.forEach((key, itemValue) {
              try {
                // Skip if itemValue is null or String
                if (itemValue == null) {
                  print('⚠️ Skipping null booking: $key');
                  return;
                }
                
                if (itemValue is String) {
                  print('⚠️ Skipping invalid booking (String): $key');
                  return;
                }
                
                if (itemValue is Map) {
                  Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
                  bookings.add(BookingModel.fromMap(itemMap, key.toString()));
                } else {
                  print('⚠️ Skipping invalid booking type: $key (${itemValue.runtimeType})');
                }
              } catch (e) {
                print('⚠️ Error parsing booking $key in stream: $e');
              }
            });
          } else {
            print('⚠️ Bookings stream data is ${value.runtimeType}, expected Map');
          }
        }
      } catch (e) {
        print('❌ Error in listenToUserBookings stream: $e');
      }
      return bookings;
    });
  }

  //MOVIE RATINGS
  Future<String> saveMovieRating(MovieRating rating) async {
    try {
      // Check if user already rated this movie
      final existingRatings = await getRatingsByMovieAndUser(rating.movieId, rating.userId);
      if (existingRatings.isNotEmpty) {
        // Update existing rating
        final existingRating = existingRatings.first;
        await _db.child('movie_ratings').child(existingRating.id).update(rating.toMap());
        return existingRating.id;
      } else {
        // Create new rating
        final ref = _db.child('movie_ratings').push();
        await ref.set(rating.toMap());
        return ref.key!;
      }
    } catch (e) {
      print('Error saving movie rating: $e');
      rethrow;
    }
  }

  Future<List<MovieRating>> getRatingsByMovie(String movieId) async {
    List<MovieRating> ratings = [];

    try {
      Query query = _db.child('movie_ratings').orderByChild('movieId').equalTo(movieId);

      DataSnapshot snapshot;
      try {
        snapshot = await query.get();
      } on FirebaseException catch (e) {
        // Xử lý lỗi permission denied
        if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
          print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc công khai movieRatings');
          print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
          // Vẫn thử fallback method
          return await _getRatingsByMovieFallback(movieId);
        }
        print('⚠️ Firebase error in query: ${e.code} - ${e.message}');
        return await _getRatingsByMovieFallback(movieId);
      } catch (e, stackTrace) {
        print('⚠️ Query snapshot error in getRatingsByMovie: $e');
        print('Stack trace: $stackTrace');
        // Fallback: Load all ratings and filter manually
        print('🔄 Falling back to manual filter method...');
        return await _getRatingsByMovieFallback(movieId);
      }

      if (!snapshot.exists || snapshot.value == null) {
        return ratings;
      }

      try {
        final value = snapshot.value;

        // Check if value is String (invalid data)
        if (value is String) {
          print('⚠️ Ratings query returned String instead of Map, skipping');
          return await _getRatingsByMovieFallback(movieId);
        }

        if (value is! Map) {
          print('⚠️ Ratings data is ${value.runtimeType}, expected Map. Skipping.');
          return await _getRatingsByMovieFallback(movieId);
        }

        Map<dynamic, dynamic> data;
        try {
          data = Map<dynamic, dynamic>.from(value);
        } catch (e) {
          print('⚠️ Error converting ratings data to Map: $e');
          return await _getRatingsByMovieFallback(movieId);
        }

        data.forEach((key, itemValue) {
          try {
            // Skip if itemValue is null or String
            if (itemValue == null) {
              print('⚠️ Skipping null rating: $key');
              return;
            }

            if (itemValue is String) {
              print('⚠️ Skipping invalid rating (String): $key');
              return;
            }

            if (itemValue is Map) {
              Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
              ratings.add(MovieRating.fromMap(itemMap, key.toString()));
            } else {
              print('⚠️ Skipping invalid rating type: $key (${itemValue.runtimeType})');
            }
          } catch (e) {
            print('⚠️ Error parsing rating $key: $e');
          }
        });
      } catch (e) {
        print('⚠️ Error processing ratings snapshot value: $e');
        return await _getRatingsByMovieFallback(movieId);
      }

    } catch (e) {
      print('❌ Error getting ratings by movie: $e');
    }

    return ratings;
  }

  // ✅ FALLBACK: Load all ratings and filter manually when query fails
  Future<List<MovieRating>> _getRatingsByMovieFallback(String movieId) async {
    List<MovieRating> ratings = [];
    
    try {
      print('🔄 Loading all ratings and filtering for movieId: $movieId');
      DataSnapshot snapshot = await _db.child('movie_ratings').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        print('ℹ️ No ratings found in database');
        return ratings;
      }

      final value = snapshot.value;

      if (value is String) {
        print('⚠️ Ratings node contains String instead of Map');
        return ratings;
      }

      if (value is! Map) {
        print('⚠️ Ratings data is ${value.runtimeType}, expected Map');
        return ratings;
      }

      try {
        Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
        print('📊 Found ${data.length} total ratings, filtering for movieId: $movieId');

        data.forEach((key, itemValue) {
          try {
            if (itemValue == null || itemValue is String) {
              return;
            }

            if (itemValue is! Map) {
              return;
            }

            Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
            
            // Filter by movieId
            final itemMovieId = itemMap['movieId']?.toString() ?? '';
            if (itemMovieId == movieId) {
              try {
                ratings.add(MovieRating.fromMap(itemMap, key.toString()));
              } catch (e) {
                print('⚠️ Error creating MovieRating for $key: $e');
              }
            }
          } catch (e) {
            print('⚠️ Error parsing rating $key: $e');
          }
        });

        print('✅ Loaded ${ratings.length} ratings for movie: $movieId (using fallback)');
      } catch (e) {
        print('⚠️ Error converting ratings data to Map: $e');
      }
    } on FirebaseException catch (e) {
      // Xử lý lỗi permission denied
      if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc công khai movieRatings');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
      }
      print('❌ Firebase error in fallback method: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Error in fallback method: $e');
      print('Stack trace: $stackTrace');
    }

    return ratings;
  }

  Future<List<MovieRating>> getRatingsByMovieAndUser(String movieId, String userId) async {
    try {
      final allRatings = await getRatingsByMovie(movieId);
      return allRatings.where((r) => r.userId == userId).toList();
    } catch (e) {
      print('Error getting ratings by movie and user: $e');
      return [];
    }
  }

  Future<double> getAverageRating(String movieId) async {
    try {
      final ratings = await getRatingsByMovie(movieId);
      if (ratings.isEmpty) return 0.0;
      final sum = ratings.fold(0.0, (sum, rating) => sum + rating.rating);
      return sum / ratings.length;
    } catch (e) {
      print('Error getting average rating: $e');
      return 0.0;
    }
  }

  //MOVIE COMMENTS
  Future<String> saveMovieComment(MovieComment comment) async {
    try {
      final ref = _db.child('movie_comments').push();
      await ref.set(comment.toMap());
      return ref.key!;
    } catch (e) {
      print('Error saving movie comment: $e');
      rethrow;
    }
  }

  Future<List<MovieComment>> getCommentsByMovie(String movieId) async {
    List<MovieComment> comments = [];

    try {
      Query query = _db.child('movie_comments').orderByChild('movieId').equalTo(movieId);

      DataSnapshot snapshot;
      try {
        snapshot = await query.get();
      } on FirebaseException catch (e) {
        // Xử lý lỗi permission denied
        if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
          print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc công khai movieComments');
          print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
          // Vẫn thử fallback method
          return await _getCommentsByMovieFallback(movieId);
        }
        print('⚠️ Firebase error in query: ${e.code} - ${e.message}');
        return await _getCommentsByMovieFallback(movieId);
      } catch (e, stackTrace) {
        print('⚠️ Query snapshot error in getCommentsByMovie: $e');
        print('Stack trace: $stackTrace');
        // Fallback: Load all comments and filter manually
        print('🔄 Falling back to manual filter method...');
        return await _getCommentsByMovieFallback(movieId);
      }

      if (!snapshot.exists || snapshot.value == null) {
        return comments;
      }

      try {
        final value = snapshot.value;
        
        // Check if value is String (invalid data)
        if (value is String) {
          print('⚠️ Comments query returned String instead of Map, skipping');
          return await _getCommentsByMovieFallback(movieId);
        }

        if (value is! Map) {
          print('⚠️ Comments data is ${value.runtimeType}, expected Map. Skipping.');
          return await _getCommentsByMovieFallback(movieId);
        }

        Map<dynamic, dynamic> data;
        try {
          data = Map<dynamic, dynamic>.from(value);
        } catch (e) {
          print('⚠️ Error converting comments data to Map: $e');
          return await _getCommentsByMovieFallback(movieId);
        }

        data.forEach((key, itemValue) {
          try {
            // Skip if itemValue is null or String
            if (itemValue == null) {
              print('⚠️ Skipping null comment: $key');
              return;
            }

            if (itemValue is String) {
              print('⚠️ Skipping invalid comment (String): $key');
              return;
            }

            if (itemValue is Map) {
              Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
              comments.add(MovieComment.fromMap(itemMap, key.toString()));
            } else {
              print('⚠️ Skipping invalid comment type: $key (${itemValue.runtimeType})');
            }
          } catch (e) {
            print('⚠️ Error parsing comment $key: $e');
          }
        });
      } catch (e) {
        print('⚠️ Error processing comments snapshot value: $e');
        return await _getCommentsByMovieFallback(movieId);
      }
    } catch (e) {
      print('❌ Error getting comments by movie: $e');
    }

    // Sort by createdAt descending (newest first)
    comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return comments;
  }

  // ✅ FALLBACK: Load all comments and filter manually when query fails
  Future<List<MovieComment>> _getCommentsByMovieFallback(String movieId) async {
    List<MovieComment> comments = [];
    
    try {
      print('🔄 Loading all comments and filtering for movieId: $movieId');
      DataSnapshot snapshot = await _db.child('movie_comments').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        print('ℹ️ No comments found in database');
        return comments;
      }

      final value = snapshot.value;

      if (value is String) {
        print('⚠️ Comments node contains String instead of Map');
        return comments;
      }

      if (value is! Map) {
        print('⚠️ Comments data is ${value.runtimeType}, expected Map');
        return comments;
      }

      try {
        Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
        print('📊 Found ${data.length} total comments, filtering for movieId: $movieId');

        data.forEach((key, itemValue) {
          try {
            if (itemValue == null || itemValue is String) {
              return;
            }

            if (itemValue is! Map) {
              return;
            }

            Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
            
            // Filter by movieId
            final itemMovieId = itemMap['movieId']?.toString() ?? '';
            if (itemMovieId == movieId) {
              try {
                comments.add(MovieComment.fromMap(itemMap, key.toString()));
              } catch (e) {
                print('⚠️ Error creating MovieComment for $key: $e');
              }
            }
          } catch (e) {
            print('⚠️ Error parsing comment $key: $e');
          }
        });

        // Sort by createdAt descending (newest first)
        comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print('✅ Loaded ${comments.length} comments for movie: $movieId (using fallback)');
      } catch (e) {
        print('⚠️ Error converting comments data to Map: $e');
      }
    } on FirebaseException catch (e) {
      // Xử lý lỗi permission denied
      if (e.code == 'PERMISSION_DENIED' || e.message?.contains('permission') == true) {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép đọc công khai movieComments');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
      }
      print('❌ Firebase error in fallback method: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Error in fallback method: $e');
      print('Stack trace: $stackTrace');
    }

    return comments;
  }

  Future<void> deleteMovieComment(String commentId) async {
    try {
      await _db.child('movie_comments').child(commentId).remove();
    } catch (e) {
      print('Error deleting movie comment: $e');
      rethrow;
    }
  }
}