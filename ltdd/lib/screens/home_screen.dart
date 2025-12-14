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
        appBar: AppBar(title: const Text('Movies')),
        body: BlocBuilder<MovieBloc, MovieState>(
          builder: (context, state) {
            if (state.movies.isEmpty) return const Center(child: CircularProgressIndicator());
            return ListView.builder(
              itemCount: state.movies.length,
              itemBuilder: (context, index) {
                MovieModel movie = state.movies[index];
                return ListTile(
                  leading: Image.network(movie.posterUrl, width: 50, fit: BoxFit.cover), // Từ Storage
                  title: Text(movie.title),
                  subtitle: Text('Genre: ${movie.genre} - Rating: ${movie.rating}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MovieDetailScreen(movieId: movie.id)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}