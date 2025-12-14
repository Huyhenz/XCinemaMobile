import 'package:firebase_database/firebase_database.dart';

class MovieModel {
  final String id; // Key từ DB
  final String title;
  final String description;
  final String genre; // Ví dụ: 'Action, Comedy'
  final int duration; // Phút
  final String posterUrl; // Từ Firebase Storage
  final double rating; // 0-10
  final int? releaseDate; // Timestamp

  MovieModel({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.duration,
    required this.posterUrl,
    this.rating = 0.0,
    this.releaseDate,
  });

  factory MovieModel.fromMap(Map<dynamic, dynamic> data, String key) {
    return MovieModel(
      id: key,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      genre: data['genre'] ?? '',
      duration: data['duration'] ?? 0,
      posterUrl: data['posterUrl'] ?? '',
      rating: data['rating']?.toDouble() ?? 0.0,
      releaseDate: data['releaseDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'genre': genre,
      'duration': duration,
      'posterUrl': posterUrl,
      'rating': rating,
      'releaseDate': ServerValue.timestamp,
    };
  }
}