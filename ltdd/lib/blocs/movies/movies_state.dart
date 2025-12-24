

import '../../models/movie.dart';

class MovieState {
  final List<MovieModel> allMovies;
  final List<MovieModel> movies; // Filtered movies
  final String? searchQuery;
  final String? category;
  final bool isLoading;

  MovieState({
    List<MovieModel>? allMovies,
    List<MovieModel>? movies,
    this.searchQuery,
    this.category,
    this.isLoading = false,
  })  : allMovies = allMovies ?? [],
        movies = movies ?? allMovies ?? [];

  MovieState copyWith({
    List<MovieModel>? allMovies,
    List<MovieModel>? movies,
    String? searchQuery,
    String? category,
    bool? isLoading,
  }) {
    return MovieState(
      allMovies: allMovies ?? this.allMovies,
      movies: movies ?? this.movies,
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}