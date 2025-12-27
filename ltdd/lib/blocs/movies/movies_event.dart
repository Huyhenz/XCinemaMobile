abstract class MovieEvent {}
class LoadMovies extends MovieEvent {
  final String? cinemaId; // Optional: Load movies by cinema
  LoadMovies({this.cinemaId});
}
class SearchMovies extends MovieEvent {
  final String query;
  SearchMovies(this.query);
}
class FilterMoviesByCategory extends MovieEvent {
  final String category; // 'nowShowing', 'comingSoon', 'popular'
  final String? cinemaId; // Optional: Filter by cinema
  FilterMoviesByCategory(this.category, {this.cinemaId});
}