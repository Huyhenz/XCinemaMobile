import 'package:firebase_database/firebase_database.dart';

class MovieModel {
  final String id; // Key từ DB
  final String title;
  final String description;
  final String genre; // Ví dụ: 'Action, Comedy'
  final int duration; // Phút
  final String posterUrl; // Từ Firebase Storage
  final String? trailerUrl; // URL của trailer (YouTube hoặc video khác)
  final String? ageRating; // Độ tuổi xem (ví dụ: "T13", "T16", "T18", "P" - Phổ thông, null = Tất cả độ tuổi)
  final int? releaseDate; // Timestamp
  final String cinemaId; // ID của rạp chiếu (phim thuộc về rạp nào)

  MovieModel({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.duration,
    required this.posterUrl,
    required this.cinemaId,
    this.trailerUrl,
    this.ageRating,
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
      cinemaId: data['cinemaId']?.toString() ?? '',
      trailerUrl: data['trailerUrl']?.toString(),
      ageRating: data['ageRating']?.toString(),
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
      'cinemaId': cinemaId,
      'trailerUrl': trailerUrl,
      'ageRating': ageRating,
      'releaseDate': releaseDate ?? ServerValue.timestamp,
    };
  }
}