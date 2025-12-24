// File: lib/services/database_services.dart
// FINAL FIX - Xử lý hoàn toàn mọi trường hợp data lỗi

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import '../models/movie.dart';
import '../models/showtime.dart';
import '../models/payment.dart';
import '../models/theater.dart';
import '../models/voucher.dart';
import '../models/tempbooking.dart';
import '../models/user.dart';

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
      return movies;
    } catch (e) {
      print('Error getting all movies: $e');
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
    final ref = _db.child('bookings').push();
    await ref.set(booking.toMap());
    return ref.key!;
  }

  // ✅ FINAL FIX: Safe query for bookings with fallback
  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    List<BookingModel> bookings = [];

    try {
      Query query = _db.child('bookings').orderByChild('userId').equalTo(userId);

      DataSnapshot snapshot;
      try {
        snapshot = await query.get();
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
      print('❌ Error in fallback method: $e');
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
}