import 'package:firebase_database/firebase_database.dart';

class MovieComment {
  final String id; // Key từ DB
  final String movieId;
  final String userId;
  final String userName; // Tên user (có thể lấy từ UserModel)
  final String content;
  final int createdAt; // Timestamp

  MovieComment({
    required this.id,
    required this.movieId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory MovieComment.fromMap(Map<dynamic, dynamic> data, String key) {
    return MovieComment(
      id: key,
      movieId: data['movieId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'Anonymous',
      content: data['content']?.toString() ?? '',
      createdAt: data['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'movieId': movieId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': ServerValue.timestamp,
    };
  }
}

