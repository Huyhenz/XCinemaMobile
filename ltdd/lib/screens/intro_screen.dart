// File: lib/screens/intro_screen.dart
// Màn hình intro hiển thị poster phim đang chiếu

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database_services.dart';
import '../models/movie.dart';
import '../widgets/main_wrapper.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  MovieModel? _movie;
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRandomMoviePoster();
    // Tự động chuyển sang MainWrapper sau 5 giây
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainWrapper(),
          ),
        );
      }
    });
  }

  Future<void> _loadRandomMoviePoster() async {
    try {
      // Load cả phim đang chiếu và sắp chiếu
      final nowShowingMovies = await DatabaseService().getMoviesShowingToday(cinemaId: null);
      final comingSoonMovies = await DatabaseService().getMoviesComingSoon(cinemaId: null);
      
      print('🎬 Intro: Loaded ${nowShowingMovies.length} movies showing today');
      print('🎬 Intro: Loaded ${comingSoonMovies.length} coming soon movies');
      
      // Kết hợp cả 2 danh sách và loại bỏ trùng lặp
      final allMovies = <MovieModel>[];
      final seenIds = <String>{};
      
      // Thêm phim đang chiếu
      for (var movie in nowShowingMovies) {
        if (!seenIds.contains(movie.id)) {
          allMovies.add(movie);
          seenIds.add(movie.id);
        }
      }
      
      // Thêm phim sắp chiếu
      for (var movie in comingSoonMovies) {
        if (!seenIds.contains(movie.id)) {
          allMovies.add(movie);
          seenIds.add(movie.id);
        }
      }
      
      if (allMovies.isNotEmpty) {
        // Chọn ngẫu nhiên 1 phim từ danh sách kết hợp
        final random = Random();
        final selectedMovie = allMovies[random.nextInt(allMovies.length)];
        
        print('🎬 Intro: Selected movie: ${selectedMovie.title}, posterUrl: ${selectedMovie.posterUrl}');
        
        if (mounted) {
          setState(() {
            _movie = selectedMovie;
            _isLoading = false;
          });
        }
      } else {
        // Nếu không có phim nào, set loading = false để hiển thị fallback
        print('⚠️ Intro: No movies available (showing today or coming soon)');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading movie poster for intro: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background poster
          _movie != null
              ? CachedNetworkImage(
                  imageUrl: _movie!.posterUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE50914),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Center(
                      child: Icon(Icons.movie, size: 80, color: Colors.grey),
                    ),
                  ),
                )
              : Container(
                  color: const Color(0xFF1A1A1A),
                ),
          
          // Gradient overlay để làm tối background (giảm opacity để poster hiển thị rõ hơn)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          
          
          // Loading indicator nếu đang load
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE50914),
              ),
            ),
        ],
      ),
    );
  }
}

