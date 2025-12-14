// Chỉnh sửa file: lib/screens/movie_detail_screen.dart
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/database_services.dart';
import 'showtimes_screen.dart'; // Import screen mới: ShowtimesScreen

class MovieDetailScreen extends StatefulWidget {
  final String movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  MovieModel? _movie;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _movie = await DatabaseService().getMovie(widget.movieId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_movie == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(_movie!.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(_movie!.posterUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_movie!.description),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShowtimesScreen(movieId: widget.movieId)),
              ),
              child: const Text('Đặt Vé'),
            ),
          ],
        ),
      ),
    );
  }
}