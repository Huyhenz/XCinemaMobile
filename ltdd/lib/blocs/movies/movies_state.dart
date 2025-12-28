

import '../../models/movie.dart';

class MovieState {
  final List<MovieModel> allMovies;
  final List<MovieModel> movies; // Filtered movies
  final String? searchQuery;
  final String? category;
  final bool isLoading;
  final String? cinemaId; // ID của rạp đã chọn

  MovieState({
    List<MovieModel>? allMovies,
    List<MovieModel>? movies,
    this.searchQuery,
    this.category,
    this.isLoading = false,
    this.cinemaId,
  })  : allMovies = allMovies ?? [],
        movies = movies ?? allMovies ?? [];

  MovieState copyWith({
    List<MovieModel>? allMovies,
    List<MovieModel>? movies,
    String? searchQuery,
    bool clearSearchQuery = false, // Flag để clear searchQuery
    String? category,
    bool? isLoading,
    String? cinemaId,
  }) {
    return MovieState(
      allMovies: allMovies ?? this.allMovies,
      movies: movies ?? this.movies,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      category: category ?? this.category,
      isLoading: isLoading ?? this.isLoading,
      cinemaId: cinemaId ?? this.cinemaId,
    );
  }
}