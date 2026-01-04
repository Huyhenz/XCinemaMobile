// File: lib/services/database_services.dart
// FINAL FIX - Xử lý hoàn toàn mọi trường hợp data lỗi

import 'dart:convert';
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
import '../models/minigame_config.dart';
import '../models/snack.dart';

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

  Future<void> deleteAllMovies() async {
    await _db.child('movies').remove();
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
      
      print('🎬 getAllMovies: Loaded ${movies.length} movies from database');
      
      // Filter out expired movies (all showtimes have passed)
      try {
        final moviesBeforeFilter = movies.length;
        movies = await _filterExpiredMovies(movies, null);
        print('🎬 getAllMovies: After filtering expired movies: ${movies.length} movies (filtered out ${moviesBeforeFilter - movies.length})');
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

  Future<void> deleteAllShowtimes() async {
    await _db.child('showtimes').remove();
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
      // Log để debug
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      print('📝 Saving booking:');
      print('   - Booking userId: ${booking.userId}');
      print('   - Current auth userId: $currentUserId');
      print('   - Match: ${booking.userId == currentUserId}');
      
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      if (booking.userId != currentUserId) {
        throw Exception('Booking userId (${booking.userId}) does not match current user ($currentUserId)');
      }
      
      final ref = _db.child('bookings').push();
      final bookingData = booking.toMap();
      print('   - Booking data keys: ${bookingData.keys.toList()}');
      print('   - Booking userId in data: ${bookingData['userId']}');
      
      await ref.set(bookingData);
      print('✅ Booking saved successfully: ${ref.key}');
      return ref.key!;
    } on FirebaseException catch (e) {
      print('❌ Firebase error saving booking: ${e.code} - ${e.message}');
      if (e.code == 'PERMISSION_DENIED' || e.message?.contains('Permission denied') == true) {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép ghi bookings');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
        print('📝 Rule cần: auth != null && (!data.exists() ? newData.child(\'userId\').val() == auth.uid : data.child(\'userId\').val() == auth.uid)');
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

  Future<void> deleteAllTheaters() async {
    await _db.child('theaters').remove();
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
      // IMPORTANT: Load movies directly from database, don't use getAllMovies() 
      // because it filters expired movies, and we want to include movies without showtimes
      List<MovieModel> allCinemaMovies = [];
      if (cinemaId != null && cinemaId.isNotEmpty) {
        allCinemaMovies = await getMoviesByCinema(cinemaId);
      } else {
        // Load all movies directly from database without filtering expired
        try {
          DataSnapshot snapshot = await _db.child('movies').get();
          if (snapshot.exists && snapshot.value != null) {
            final value = snapshot.value;
            if (value is Map) {
              Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
              data.forEach((key, itemValue) {
                try {
                  if (itemValue is Map) {
                    final itemMap = Map<dynamic, dynamic>.from(itemValue);
                    allCinemaMovies.add(MovieModel.fromMap(itemMap, key.toString()));
                  }
                } catch (e) {
                  print('⚠️ Error parsing movie $key: $e');
                }
              });
            }
          }
          print('🎬 getMoviesComingSoon: Loaded ${allCinemaMovies.length} movies directly from database');
        } catch (e) {
          print('⚠️ Error loading movies directly: $e');
          // Fallback to getAllMovies if direct load fails
          allCinemaMovies = await getAllMovies();
        }
      }

      // Get theaters of this cinema if cinemaId is specified
      Set<String> theaterIds = {};
      if (cinemaId != null && cinemaId.isNotEmpty) {
        List<TheaterModel> theaters = await getTheatersByCinema(cinemaId);
        theaterIds = theaters.map((t) => t.id).toSet();
      }

      // Get all showtimes to find which movies have showtimes
      Set<String> moviesWithShowtimesToday = {}; // Movies with showtimes today
      Set<String> moviesWithShowtimesFuture = {}; // Movies with showtimes from tomorrow onwards
      Set<String> allMoviesWithShowtimes = {}; // All movies that have any showtimes
      
      try {
        DataSnapshot showtimesSnapshot = await _db.child('showtimes').get();
        
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
        } else {
          print('🎬 getMoviesComingSoon: No showtimes found in database (all movies will be considered as coming soon)');
        }
      } catch (e) {
        print('⚠️ Error reading showtimes in getMoviesComingSoon: $e');
        print('⚠️ Continuing with empty showtimes list - all movies will be considered as coming soon');
        // Continue with empty sets - all movies will be included in coming soon
      }

      // Filter movies: All movies of cinema EXCEPT those with showtimes today
      // This includes:
      // 1. Movies with no showtimes at all (ALWAYS include these)
      // 2. Movies with showtimes from tomorrow onwards (ALWAYS include these)
      // 3. Movies with showtimes but not today (only include if not all expired)
      List<MovieModel> movies = [];
      int moviesWithShowtimesTodayCount = 0;
      int moviesWithoutShowtimesCount = 0;
      int moviesWithFutureShowtimesCount = 0;
      int moviesWithPastShowtimesCount = 0;
      
      for (var movie in allCinemaMovies) {
        // If movie has showtimes today, skip it (it's in "now showing")
        if (moviesWithShowtimesToday.contains(movie.id)) {
          moviesWithShowtimesTodayCount++;
          continue; // Skip movies with showtimes today
        }
        
        // Check if movie has no showtimes at all - ALWAYS include
        if (!allMoviesWithShowtimes.contains(movie.id)) {
          moviesWithoutShowtimesCount++;
          movies.add(movie);
          continue;
        }
        
        // Movie has showtimes - check if it has future showtimes
        if (moviesWithShowtimesFuture.contains(movie.id)) {
          // Movie has showtimes from tomorrow onwards - ALWAYS include
          moviesWithFutureShowtimesCount++;
          movies.add(movie);
        } else {
          // Movie has showtimes but not today and not future
          // This means it only has past showtimes - we'll filter these out later
          moviesWithPastShowtimesCount++;
          // Don't add yet - will be filtered by _filterExpiredMovies
        }
      }

      print('🎬 getMoviesComingSoon: Before filtering expired movies: ${movies.length} movies');
      print('🎬   - Total movies from DB: ${allCinemaMovies.length}');
      print('🎬   - Movies with showtimes today: $moviesWithShowtimesTodayCount (excluded)');
      print('🎬   - Movies with no showtimes: $moviesWithoutShowtimesCount (included)');
      print('🎬   - Movies with future showtimes: $moviesWithFutureShowtimesCount (included)');
      print('🎬   - Movies with only past showtimes: $moviesWithPastShowtimesCount (will be filtered)');
      print('🎬   - Movies with showtimes (any): ${allMoviesWithShowtimes.length}');

      // Filter out expired movies (all showtimes have passed)
      // Note: This will only filter movies that have showtimes but ALL are expired
      // Movies with no showtimes are already added and will be kept
      // Movies with future showtimes are already added and will be kept
      final moviesBeforeExpiredFilter = movies.length;
      movies = await _filterExpiredMovies(movies, cinemaId);
      final moviesAfterExpiredFilter = movies.length;
      
      print('🎬 getMoviesComingSoon: After filtering expired movies: ${movies.length} movies');
      print('🎬   - Filtered out ${moviesBeforeExpiredFilter - moviesAfterExpiredFilter} expired movies');
      print('🎬 getMoviesComingSoon: Returning ${movies.length} movies for cinema ${cinemaId ?? "all"}');

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
      int noShowtimesCount = 0;
      int hasFutureShowtimesCount = 0;
      
      for (var movie in movies) {
        final movieShowtimesList = movieShowtimes[movie.id] ?? [];
        
        if (movieShowtimesList.isEmpty) {
          // Movie has no showtimes - not expired, keep it
          noShowtimesCount++;
          filteredMovies.add(movie);
        } else {
          // Movie has showtimes - check if ALL are expired
          final hasFutureShowtime = movieShowtimesList.any((startTime) => startTime >= nowMillis);
          
          if (hasFutureShowtime) {
            // Has at least one future showtime - not expired, keep it
            hasFutureShowtimesCount++;
            filteredMovies.add(movie);
          } else {
            // All showtimes are expired - remove it
            expiredCount++;
            print('🗑️ Filtering out expired movie: ${movie.title} (all ${movieShowtimesList.length} showtimes have passed)');
          }
        }
      }
      
      print('🎬 _filterExpiredMovies: Input ${movies.length} movies, Output ${filteredMovies.length} movies');
      print('🎬   - Movies with no showtimes: $noShowtimesCount (kept)');
      print('🎬   - Movies with future showtimes: $hasFutureShowtimesCount (kept)');
      if (expiredCount > 0) {
        print('🎬   - Expired movies filtered out: $expiredCount');
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
      // Log để debug
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      print('📝 Creating notification:');
      print('   - Notification userId: $userId');
      print('   - Current auth userId: $currentUserId');
      print('   - Match: ${userId == currentUserId}');
      
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      final ref = _db.child('notifications').push();
      final notificationData = {
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': ServerValue.timestamp,
      };
      print('   - Notification data keys: ${notificationData.keys.toList()}');
      print('   - Notification userId in data: ${notificationData['userId']}');
      
      await ref.set(notificationData);
      print('✅ Notification created successfully: ${ref.key}');
      return ref.key!;
    } on FirebaseException catch (e) {
      print('❌ Firebase error creating notification: ${e.code} - ${e.message}');
      if (e.code == 'PERMISSION_DENIED' || e.message?.contains('Permission denied') == true) {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép ghi notifications');
        print('📝 Xem file FIREBASE_RULES_UPDATE.md để biết cách cập nhật rules');
        print('📝 Rule cần: auth != null');
      }
      rethrow;
    } catch (e) {
      print('❌ Error creating notification: $e');
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

  // ✅ Helper method để lưu temp_registrations an toàn
  Future<void> saveTempRegistration(String userId, Map<String, dynamic> data) async {
    try {
      print('📝 Saving temp_registrations for user: $userId');
      print('📝 Data: $data');
      
      // Đảm bảo tất cả giá trị đều là primitive types (String, int, double, bool, null)
      Map<String, dynamic> cleanData = {};
      data.forEach((key, value) {
        if (value is String || value is int || value is double || value is bool || value == null) {
          cleanData[key] = value;
        } else {
          // Convert các kiểu khác thành String
          cleanData[key] = value.toString();
          print('⚠️ Converted $key from ${value.runtimeType} to String: ${value.toString()}');
        }
      });
      
      await _db.child('temp_registrations').child(userId).set(cleanData);
      print('✅ Saved temp_registrations successfully');
    } catch (e) {
      print('❌ Error saving temp_registrations: $e');
      rethrow;
    }
  }

  // ✅ Helper method để đọc temp_registrations an toàn
  // Sử dụng onValue listener để đọc raw data và xử lý cả String và Map
  Future<Map<dynamic, dynamic>?> getTempRegistration(String userId) async {
    print('📝 Attempting to get temp_registrations for user: $userId');
    
    try {
      // Sử dụng once() để đọc data một lần (trả về Stream)
      final event = await _db.child('temp_registrations').child(userId).once();
      
      if (!event.snapshot.exists) {
        print('ℹ️ temp_registrations does not exist for user: $userId');
        return null;
      }
      
      final value = event.snapshot.value;
      
      if (value == null) {
        print('ℹ️ temp_registrations value is null for user: $userId');
        return null;
      }

      print('📝 Raw value type: ${value.runtimeType}');
      
      // Xử lý trường hợp value là String (JSON string)
      if (value is String) {
        print('⚠️ temp_registrations is stored as String, attempting to parse JSON...');
        try {
          // Thử parse JSON
          final decoded = jsonDecode(value);
          if (decoded is Map) {
            final mapData = Map<dynamic, dynamic>.from(decoded);
            print('✅ Successfully parsed JSON string: $mapData');
            
            // Fix data: Lưu lại dưới dạng Map để lần sau không cần parse
            try {
              await _db.child('temp_registrations').child(userId).set(mapData);
              print('✅ Fixed and saved temp_registrations as Map');
            } catch (e) {
              print('⚠️ Error fixing temp_registrations: $e');
            }
            
            return mapData;
          } else {
            print('⚠️ Parsed JSON is not a Map: ${decoded.runtimeType}');
            // Xóa corrupt data
            try {
              await _db.child('temp_registrations').child(userId).remove();
              print('✅ Removed corrupt temp_registrations data');
            } catch (e) {
              print('⚠️ Error removing corrupt data: $e');
            }
            return null;
          }
        } catch (e) {
          print('⚠️ Error parsing JSON string: $e');
          print('⚠️ Raw string value: $value');
          // Nếu không parse được JSON, xóa corrupt data
          try {
            await _db.child('temp_registrations').child(userId).remove();
            print('✅ Removed corrupt temp_registrations data');
          } catch (removeError) {
            print('⚠️ Error removing corrupt data: $removeError');
          }
          return null;
        }
      }
      
      // Xử lý trường hợp value là Map
      if (value is Map) {
        try {
          final mapData = Map<dynamic, dynamic>.from(value);
          print('✅ Successfully parsed temp_registrations (Map): $mapData');
          return mapData;
        } catch (e) {
          print('⚠️ Error converting Map: $e');
          return null;
        }
      }
      
      // Nếu không phải Map hoặc String
      print('⚠️ temp_registrations has unexpected type: ${value.runtimeType}');
      return null;
      
    } on FirebaseException catch (e, stackTrace) {
      print('⚠️ FirebaseException getting temp_registrations: ${e.code} - ${e.message}');
      print('⚠️ Stack trace: $stackTrace');
      return null;
    } catch (e, stackTrace) {
      // Xử lý các exception khác (bao gồm TypeError)
      print('❌ Unexpected error getting temp_registrations: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // Nếu là TypeError về String/Map, thử xóa và return null
      if (e.toString().contains('String') && e.toString().contains('Map')) {
        print('⚠️ Detected String/Map type error, attempting to remove corrupt data...');
        try {
          await _db.child('temp_registrations').child(userId).remove();
          print('✅ Removed potentially corrupt temp_registrations');
        } catch (removeError) {
          print('⚠️ Error removing corrupt data: $removeError');
        }
      }
      
      return null;
    }
  }

  // ✅ Helper method để cập nhật user từ temp_registrations nếu các trường null
  Future<void> updateUserFromTempRegistration(String userId) async {
    try {
      UserModel? existingUser = await getUser(userId);
      if (existingUser == null) {
        print('⚠️ User not found, cannot update from temp_registrations');
        return;
      }

      // Kiểm tra xem có cần cập nhật không
      if (existingUser.phone != null && existingUser.dateOfBirth != null) {
        print('ℹ️ User already has phone and dateOfBirth, no need to update');
        return;
      }

      // Lấy temp_registrations
      Map<dynamic, dynamic>? tempData = await getTempRegistration(userId);
      if (tempData == null) {
        print('ℹ️ No temp_registrations found for user');
        return;
      }

      // Chuẩn bị updates
      Map<String, dynamic> updates = {};
      
      // Parse phone
      if (existingUser.phone == null) {
        final phoneValue = tempData['phone'];
        if (phoneValue != null && phoneValue.toString().trim().isNotEmpty) {
          updates['phone'] = phoneValue.toString().trim();
        }
      }
      
      // Parse dateOfBirth
      if (existingUser.dateOfBirth == null) {
        final dateOfBirthValue = tempData['dateOfBirth'];
        if (dateOfBirthValue != null) {
          if (dateOfBirthValue is int) {
            updates['dateOfBirth'] = dateOfBirthValue;
          } else if (dateOfBirthValue is num) {
            updates['dateOfBirth'] = dateOfBirthValue.toInt();
          } else {
            final parsed = int.tryParse(dateOfBirthValue.toString());
            if (parsed != null) {
              updates['dateOfBirth'] = parsed;
            }
          }
        }
      }
      
      // Parse name (nếu là "New User")
      if (existingUser.name == 'New User' || existingUser.name.isEmpty) {
        final nameValue = tempData['name'];
        if (nameValue != null && nameValue.toString().trim().isNotEmpty) {
          updates['name'] = nameValue.toString().trim();
        }
      }

      // Cập nhật nếu có thay đổi
      if (updates.isNotEmpty) {
        print('📝 Updating user from temp_registrations: $updates');
        await updateUser(userId, updates);
        print('✅ Updated user from temp_registrations');
        
        // Xóa temp_registrations sau khi cập nhật thành công
        try {
          await _db.child('temp_registrations').child(userId).remove();
          print('✅ Removed temp_registrations after update');
        } catch (e) {
          print('⚠️ Error removing temp_registrations: $e');
        }
      } else {
        print('ℹ️ No updates needed from temp_registrations');
      }
    } catch (e, stackTrace) {
      print('❌ Error updating user from temp_registrations: $e');
      print('❌ Stack trace: $stackTrace');
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

  //MINIGAME CONFIG
  Future<void> saveMinigameConfig(MinigameConfig config) async {
    try {
      await _db.child('minigame_configs').child(config.gameId).set(config.toMap());
    } catch (e) {
      print('Error saving minigame config: $e');
      rethrow;
    }
  }

  Future<MinigameConfig?> getMinigameConfig(String gameId) async {
    try {
      DataSnapshot snapshot = await _db.child('minigame_configs').child(gameId).get();
      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;
        
        // Kiểm tra nếu value là String (invalid data)
        if (value is String) {
          print('⚠️ Minigame config for $gameId is String instead of Map, skipping');
          return null;
        }
        
        // Kiểm tra nếu value không phải Map
        if (value is! Map) {
          print('⚠️ Minigame config for $gameId is ${value.runtimeType} instead of Map, skipping');
          return null;
        }
        
        final data = _convertMap(value);
        if (data.isNotEmpty) {
          return MinigameConfig.fromMap(data, gameId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting minigame config: $e');
      return null;
    }
  }

  Future<List<MinigameConfig>> getAllMinigameConfigs() async {
    try {
      DataSnapshot snapshot = await _db.child('minigame_configs').get();
      List<MinigameConfig> configs = [];

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;

        // Kiểm tra nếu value là String (invalid data)
        if (value is String) {
          print('⚠️ Minigame configs node contains String instead of Map');
          return configs;
        }

        if (value is Map) {
          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
          data.forEach((key, itemValue) {
            try {
              // Bỏ qua nếu itemValue là String hoặc null
              if (itemValue == null) {
                print('⚠️ Skipping null minigame config: $key');
                return;
              }
              
              if (itemValue is String) {
                print('⚠️ Skipping invalid minigame config (String): $key');
                return;
              }
              
              if (itemValue is Map) {
                Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
                configs.add(MinigameConfig.fromMap(itemMap, key.toString()));
              } else {
                print('⚠️ Skipping invalid minigame config type: $key (${itemValue.runtimeType})');
              }
            } catch (e) {
              print('⚠️ Error parsing minigame config $key: $e');
            }
          });
        } else {
          print('⚠️ Minigame configs data is ${value.runtimeType}, expected Map');
        }
      }
      return configs;
    } catch (e) {
      print('Error getting all minigame configs: $e');
      return [];
    }
  }

  Future<void> updateMinigameConfig(MinigameConfig config) async {
    try {
      await _db.child('minigame_configs').child(config.gameId).update(config.toMap());
    } catch (e) {
      print('Error updating minigame config: $e');
      rethrow;
    }
  }

  //SNACK
  Future<String> saveSnack(SnackModel snack) async {
    try {
      final ref = _db.child('snacks').push();
      await ref.set(snack.toMap());
      return ref.key!;
    } on FirebaseException catch (e) {
      print('❌ Firebase error saving snack: ${e.code} - ${e.message}');
      if (e.code == 'PERMISSION_DENIED' || e.message?.contains('Permission denied') == true) {
        print('⚠️ Permission denied: Vui lòng cập nhật Firebase rules để cho phép ghi snacks');
        print('📝 Xem file FIREBASE_SNACKS_RULES.md để biết cách cập nhật rules');
        print('📝 Rule cần: "snacks": { ".read": true, ".write": "auth != null" }');
      }
      rethrow;
    } catch (e) {
      print('❌ Error saving snack: $e');
      rethrow;
    }
  }

  Future<SnackModel?> getSnack(String snackId) async {
    try {
      DataSnapshot snapshot = await _db.child('snacks').child(snackId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = _convertMap(snapshot.value);
        if (data.isNotEmpty) {
          return SnackModel.fromMap(data, snackId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting snack: $e');
      return null;
    }
  }

  Future<List<SnackModel>> getAllSnacks() async {
    try {
      DataSnapshot snapshot = await _db.child('snacks').get();
      List<SnackModel> snacks = [];

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;

        if (value is Map) {
          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
          data.forEach((key, itemValue) {
            try {
              if (itemValue is Map) {
                Map<dynamic, dynamic> itemMap = Map<dynamic, dynamic>.from(itemValue);
                snacks.add(SnackModel.fromMap(itemMap, key.toString()));
              }
            } catch (e) {
              print('⚠️ Error parsing snack $key: $e');
            }
          });
        }
      }
      return snacks;
    } catch (e) {
      print('Error getting all snacks: $e');
      return [];
    }
  }

  Future<void> updateSnack(SnackModel snack) async {
    try {
      await _db.child('snacks').child(snack.id).update(snack.toMap());
    } catch (e) {
      print('Error updating snack: $e');
      rethrow;
    }
  }

  Future<void> deleteSnack(String snackId) async {
    try {
      await _db.child('snacks').child(snackId).remove();
    } catch (e) {
      print('Error deleting snack: $e');
      rethrow;
    }
  }
}