// Updated: lib/screens/movie_detail_screen.dart
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
    if (_movie == null) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blue)));
    return Scaffold(
      appBar: AppBar(
        title: Text(_movie!.title),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.network(_movie!.posterUrl, height: 300, width: double.infinity, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _movie!.description,
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShowtimesScreen(movieId: widget.movieId)),
                ),
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  shadowColor: MaterialStateProperty.all(Colors.blue.shade300),
                  elevation: MaterialStateProperty.all(8),
                  foregroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.hovered)) {
                      return Colors.blue.shade900; // In đậm khi hover
                    }
                    return Colors.blue.shade700;
                  }),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'Đặt Vé',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}