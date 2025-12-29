import 'package:firebase_database/firebase_database.dart';

class MovieRating {
  final String id; // Key từ DB
  final String movieId;
  final String userId;
  final double rating; // 1-5 stars (0.5 increments)
  final int createdAt; // Timestamp

  MovieRating({
    required this.id,
    required this.movieId,
    required this.userId,
    required this.rating,
    required this.createdAt,
  });

  factory MovieRating.fromMap(Map<dynamic, dynamic> data, String key) {
    return MovieRating(
      id: key,
      movieId: data['movieId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      rating: data['rating']?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'movieId': movieId,
      'userId': userId,
      'rating': rating,
      'createdAt': ServerValue.timestamp,
    };
  }
}

