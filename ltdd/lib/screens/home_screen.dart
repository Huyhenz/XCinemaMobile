// Updated: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/movies/movies_bloc.dart';
import '../blocs/movies/movies_event.dart';
import '../blocs/movies/movies_state.dart';
import '../models/movie.dart';
import 'movie_detail_screen.dart'; // Import screen detail

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovieBloc()..add(LoadMovies()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Danh Sách Phim'),
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
          child: BlocBuilder<MovieBloc, MovieState>(
            builder: (context, state) {
              if (state.movies.isEmpty) return const Center(child: CircularProgressIndicator(color: Colors.blue));
              return ListView.builder(
                itemCount: state.movies.length,
                itemBuilder: (context, index) {
                  MovieModel movie = state.movies[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: Colors.white,
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(movie.posterUrl, width: 50, fit: BoxFit.cover),
                      ),
                      title: Text(movie.title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      subtitle: Text('Thể Loại: ${movie.genre} - Đánh Giá: ${movie.rating}', style: TextStyle(color: Colors.black54)),
                      trailing: Icon(Icons.arrow_forward, color: Colors.blue.shade700),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MovieDetailScreen(movieId: movie.id)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}